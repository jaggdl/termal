# frozen_string_literal: true

module Api
  class MealsController < BaseController
    def show
      meal = Current.user.meals.find(params[:id])
      render json: MealSerializer.new(meal)
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Meal not found" }, status: :not_found
    end

    def search
      meals = Meal.search_by_nutrients(user: Current.user, params: params)
      render json: { meals: meals.map { |meal| MealSerializer.new(meal).as_json } }
    rescue ArgumentError => e
      render json: { error: "Invalid parameter: #{e.message}" }, status: :bad_request
    end
  end
end
