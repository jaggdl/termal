class NutritionSummaryController < ApplicationController
  def show
    @period = (params[:period] || "7").to_i

    @selected_nutrient = params[:nutrient] || "calories"

    @query = params[:query]

    @selected_meal_ids = params[:selected_meal_ids] || []

    summary = Current.user.nutrition_summary(period: @period, query: @query, selected_meal_ids: @selected_meal_ids)

    @summary = summary.data

    @matching_meals = summary.matching_meals if @query.present?
  end
end
