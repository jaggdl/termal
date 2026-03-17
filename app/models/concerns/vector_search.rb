module VectorSearch
  extend ActiveSupport::Concern

  included do
    has_one :meal_vector, foreign_key: "meal_id"
    after_save :update_vector_embedding
    attr_accessor :combined_score
  end

  def content_for_embedding
    "#{meal_name} #{description}"
  end

  def update_vector_embedding
    find_or_create_meal_vector
  end

  def find_or_create_meal_vector
    return unless meal_name.present?

    MealVector.find_or_create_by!(meal_id: id) do |vector|
      vector.embedding = Embedding.create(content_for_embedding).embedding
    end
  end

  class_methods do
    def interaction_score_sql
      time_decay = "((CAST(strftime('%s', 'now') AS REAL) - CAST(strftime('%s', user_meals.consumed_at) AS REAL)) / 86400.0)"
      hour_diff = "MIN(ABS(CAST(strftime('%H', 'now') AS INTEGER) - CAST(strftime('%H', user_meals.consumed_at) AS INTEGER)), 24 - ABS(CAST(strftime('%H', 'now') AS INTEGER) - CAST(strftime('%H', user_meals.consumed_at) AS INTEGER)))"
      "SUM(exp(-? * #{time_decay} - ? * #{hour_diff}))"
    end

    def most_common_meals(user:, limit: 5, offset: 0, time_decay_rate: 0.1, hour_penalty: 0.05)
      sql = <<~SQL
        SELECT meals.*,
               COUNT(user_meals.id) AS consumption_count,
               #{interaction_score_sql} AS interaction_score
        FROM meals
        INNER JOIN user_meals ON meals.id = user_meals.meal_id
        WHERE user_meals.user_id = ?
        GROUP BY meals.id
        ORDER BY interaction_score DESC
        LIMIT ? OFFSET ?
      SQL

      find_by_sql([ sql, time_decay_rate, hour_penalty, user.id, limit, offset ])
    end

    def vector_search(query:, user:, limit: 5, offset: 0, time_decay_rate: 0.1, interaction_weight: 0.03, hour_penalty: 0.05)
      query_embedding = QueryEmbedding.find_or_create_embedding(query)
      embedding = query_embedding.embedding

      # Get user's unique meal IDs first - fast indexed lookup
      user_meal_ids = UserMeal.where(user_id: user.id).distinct.pluck(:meal_id)

      return [] if user_meal_ids.empty?

      # First do vector search on all vectors (fast, uses index)
      # Then filter to user's meals (fast, indexed)
      vector_sql = <<~SQL
        SELECT meal_id, distance
        FROM meal_vectors
        WHERE embedding MATCH ? AND k = ?
      SQL
      vector_results = MealVector.find_by_sql([
        vector_sql,
        embedding.to_s,
        [ user_meal_ids.length, limit * 10 ].max
      ])

      # Filter to user's meals in Ruby (fast, small dataset)
      user_vector_results = vector_results.select { |vr| user_meal_ids.include?(vr.meal_id) }
      user_meal_ids_from_vector = user_vector_results.map(&:meal_id)

      return [] if user_meal_ids_from_vector.empty?

      # Now query for full meal data with interaction scores
      placeholders = user_meal_ids_from_vector.map { "?" }.join(",")
      sql = <<~SQL
        SELECT meals.*,
               #{interaction_score_sql} AS interaction_score
        FROM meals
        INNER JOIN user_meals ON meals.id = user_meals.meal_id
        WHERE user_meals.user_id = ?
          AND meals.id IN (#{placeholders})
        GROUP BY meals.id
      SQL

      results = find_by_sql([
        sql,
        time_decay_rate,
        hour_penalty,
        user.id,
        *user_meal_ids_from_vector
      ])

      # Calculate combined scores in Ruby
      results.each do |meal|
        vector_result = user_vector_results.find { |vr| vr.meal_id == meal.id }
        distance = vector_result ? vector_result.distance : 1.0
        interaction_score = meal.attributes["interaction_score"].to_f
        meal.combined_score = (1.0 / (1.0 + distance)) + interaction_weight * interaction_score
      end

      # Sort by combined score and apply limit/offset
      results.sort_by { |m| -m.combined_score }.drop(offset).first(limit)
    end
  end
end
