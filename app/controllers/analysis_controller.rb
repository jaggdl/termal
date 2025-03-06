class AnalysisController < ApplicationController
  def index
    # Get all analyses for the current user, ordered by most recent first
    @analyses = Current.user.nutrition_analyses.order(executed_at: :desc)
  end

  def show
    # Get period from params or default to 7 days
    @period = 7

    # Use our nutrition summary service to get all data
    @summary = NutritionSummaryService.new(Current.user, period: @period).summary_data

    # Find the analysis based on ID from params or the most recent one
    @analysis = if params[:id] == "latest" || params[:id].nil?
                  Current.user.nutrition_analyses.order(executed_at: :desc).first
                else
                  Current.user.nutrition_analyses.find(params[:id])
                end
  end

  def create
    include_meal_data = params[:include_meal_data] == "1"
    AnalyzeNutritionJob.perform_later(Current.user.id, include_meal_data)
    
    # Redirect back to analysis index page with notice
    redirect_to analysis_index_path, notice: "Analysis job has been queued. Check back shortly."
  end
end
