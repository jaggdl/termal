class AnalysisController < ApplicationController
  def index
    @analyses = Current.user.nutrition_analyses.order(executed_at: :desc)
  end

  def show
    @analysis = Current.user.nutrition_analyses.find(params[:id])
  end

  def create
    include_meal_data = params[:include_meal_data] == "1"
    period = params[:period] || "last_week"

    AnalyzeNutritionJob.perform_later(Current.user.id, include_meal_data, period)

    redirect_to analysis_index_path, notice: "Analysis job has been queued. Check back shortly."
  end
end
