module VectorSearch
  extend ActiveSupport::Concern

  included do
    has_one :meal_vector, foreign_key: "meal_id"
    after_save :update_vector_embedding
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

      sql = <<~SQL
        SELECT meals.*,
               distance,
               (1.0 / (1.0 + distance)) + ? * #{interaction_score_sql} AS combined_score
        FROM meals
        INNER JOIN meal_vectors ON meals.id = meal_vectors.meal_id
        INNER JOIN user_meals ON meals.id = user_meals.meal_id
        WHERE user_meals.user_id = ?
          AND meal_vectors.embedding MATCH ? AND k = ?
        GROUP BY meals.id, distance
        ORDER BY combined_score DESC
        LIMIT ? OFFSET ?
      SQL

      find_by_sql([ sql, interaction_weight, time_decay_rate, hour_penalty, user.id, embedding.to_s, limit * 10, limit, offset ])
    end
  end
end
