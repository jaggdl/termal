class NutritionSummaryController < ApplicationController
  def show
    @period = (params[:period] || "7").to_i

    @selected_nutrient = params[:nutrient] || "calories"

    @summary = NutritionSummaryService.new(Current.user, period: @period).summary_data
  end
end
