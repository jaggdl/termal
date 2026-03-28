class NutritionSummaryController < ApplicationController
  def show
    @period = (params[:period] || "7").to_i

    @selected_nutrient = params[:nutrient] || "calories"

    @query = params[:query]

    @summary = NutritionSummaryService.new(Current.user, period: @period, query: @query).summary_data
  end
end
