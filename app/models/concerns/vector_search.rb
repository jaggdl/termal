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
    def vector_search(query:, user:, limit: 5, offset: 0, alpha: 0.1, beta: 0.01)
      query_embedding = QueryEmbedding.find_or_create_embedding(query)
      embedding = query_embedding.embedding

      sql = <<~SQL
        SELECT meals.*,
               distance,
               SUM(exp(-? * ((CAST(strftime('%s', 'now') AS REAL) - CAST(strftime('%s', user_meals.consumed_at) AS REAL)) / 86400.0))) AS interaction_score,
               (1.0 / (1.0 + distance)) + ? * SUM(exp(-? * ((CAST(strftime('%s', 'now') AS REAL) - CAST(strftime('%s', user_meals.consumed_at) AS REAL)) / 86400.0))) AS combined_score
        FROM meals
        INNER JOIN meal_vectors ON meals.id = meal_vectors.meal_id
        INNER JOIN user_meals ON meals.id = user_meals.meal_id
        WHERE user_meals.user_id = ?
          AND meal_vectors.embedding MATCH ? AND k = ?
        GROUP BY meals.id, distance
        ORDER BY combined_score DESC
        LIMIT ? OFFSET ?
      SQL

      find_by_sql([ sql, alpha, beta, alpha, user.id, embedding.to_s, limit * 10, limit, offset ])
    end
  end
end
