module VectorSearch
  extend ActiveSupport::Concern

  included do
    has_one :meal_vector, foreign_key: "meal_id"
    after_save :update_vector_embedding
  end

  def weighted_content_for_embedding
    text = meal_name.to_s
    text += " " + (description.to_s) if description.present?
    text
  end

  def update_vector_embedding
    find_or_create_meal_vector
  end

  def find_or_create_meal_vector
    return unless meal_name.present?

    vector = MealVector.find_or_create_by!(meal_id: id)

    vector.embedding = Embedding.create(weighted_content_for_embedding).embedding
    vector.save!
    vector
  end

  class_methods do
    def vector_search(query:, user:, limit: 5)
      embedding = Embedding.create(query)

      sql = <<~SQL
        SELECT meals.*#{' '}
        FROM meals
        INNER JOIN meal_vectors ON meals.id = meal_vectors.meal_id
        INNER JOIN user_meals ON meals.id = user_meals.meal_id
        WHERE user_meals.user_id = ?
        AND embedding MATCH ? AND k = ?
        GROUP BY meals.id
        ORDER BY distance
      SQL

      find_by_sql([ sql, user.id, embedding.to_s, limit ])
    end
  end
end
