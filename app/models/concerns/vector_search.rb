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
    def vector_search(...)
      Meal::Search.vector_search(...)
    end

    def most_common_meals(...)
      Meal::Search.most_common_meals(...)
    end
  end
end
