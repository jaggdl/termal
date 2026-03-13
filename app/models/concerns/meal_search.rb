# frozen_string_literal: true

module MealSearch
  extend ActiveSupport::Concern

  NUTRIENT_COLUMNS = %w[calories proteins carbs fats].freeze
  DEFAULT_SEARCH_LIMIT = 20
  MAX_SEARCH_LIMIT = 100

  class_methods do
    def search_by_nutrients(user:, params:)
      meals = user.meals

      NUTRIENT_COLUMNS.each do |nutrient|
        meals = apply_nutrient_range(
          meals,
          nutrient,
          params["#{nutrient}_min"],
          params["#{nutrient}_max"]
        )
      end

      limit = [ params[:limit].to_i, MAX_SEARCH_LIMIT ].min
      limit = DEFAULT_SEARCH_LIMIT if limit <= 0

      meals.order(created_at: :desc).limit(limit)
    end

    private

    def apply_nutrient_range(scope, nutrient, min_value, max_value)
      scope = scope.where("#{nutrient} >= ?", min_value.to_f) if min_value.present?
      scope = scope.where("#{nutrient} <= ?", max_value.to_f) if max_value.present?
      scope
    end
  end
end
