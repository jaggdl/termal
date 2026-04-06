# frozen_string_literal: true

module MealSearch
  extend ActiveSupport::Concern

  NUTRIENT_COLUMNS = %w[calories proteins carbs fats].freeze
  DEFAULT_SEARCH_LIMIT = 20
  MAX_SEARCH_LIMIT = 100

  class_methods do
    def search(user:, params:)
      if params[:query].present?
        search_by_vector(user:, params:)
      else
        search_by_nutrients(user:, params:)
      end
    end

    private

    def search_by_nutrients(user:, params:)
      filter_and_limit(user.meals, params).order(created_at: :desc)
    end

    def search_by_vector(user:, params:)
      limit = extract_limit(params)
      meal_ids = fetch_vector_meal_ids(params[:query], limit)

      return Meal.none if meal_ids.empty?

      meals = user.meals.where(id: meal_ids).joins(:meal_vector)
      filter_and_limit(meals, params).order(Arel.sql("meal_vectors.distance ASC"))
    end

    def fetch_vector_meal_ids(query, limit)
      return [] if query.blank?

      query_embedding = QueryEmbedding.find_or_create_embedding(query)
      embedding = query_embedding.embedding

      vector_results = MealVector.find_by_sql([
        "SELECT meal_id, distance FROM meal_vectors WHERE embedding MATCH ? AND k = ?",
        embedding.to_s,
        limit * 5
      ])

      vector_results.map(&:meal_id)
    end

    def apply_nutrient_filters(meals, params)
      NUTRIENT_COLUMNS.each do |nutrient|
        meals = apply_nutrient_range(
          meals,
          nutrient,
          params["#{nutrient}_min"],
          params["#{nutrient}_max"]
        )
      end
      meals
    end

    def filter_and_limit(meals, params)
      limit = extract_limit(params)
      apply_nutrient_filters(meals, params).limit(limit)
    end

    def extract_limit(params)
      limit = [ params[:limit].to_i, MAX_SEARCH_LIMIT ].min
      limit = DEFAULT_SEARCH_LIMIT if limit <= 0
      limit
    end

    def apply_nutrient_range(scope, nutrient, min_value, max_value)
      scope = scope.where("#{nutrient} >= ?", min_value.to_f) if min_value.present?
      scope = scope.where("#{nutrient} <= ?", max_value.to_f) if max_value.present?
      scope
    end
  end
end
