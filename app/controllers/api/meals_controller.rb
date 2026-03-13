# frozen_string_literal: true

module Api
  class MealsController < BaseController
    def search
      meals = Meal.search_by_nutrients(user: Current.user, params: params)
      render json: { meals: meals.map { |meal| MealSerializer.new(meal).as_json } }
    rescue ArgumentError => e
      render json: { error: "Invalid parameter: #{e.message}" }, status: :bad_request
    end
  end
end
