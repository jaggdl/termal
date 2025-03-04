class NutritionSummaryController < ApplicationController
  def show
    # Get period from params or default to 7 days
    @period = (params[:period] || "7").to_i

    # Get selected nutrient or default to calories
    @selected_nutrient = params[:nutrient] || "calories"

    # Use our nutrition summary service to get all data
    @summary = NutritionSummaryService.new(Current.user, period: @period).summary_data
  end
end
