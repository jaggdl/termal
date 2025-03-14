class NutritionAnalysesController < ApplicationController
  def index
    @analyses = Current.user.nutrition_analyses.order(executed_at: :desc)
  end

  def show
    @analysis = Current.user.nutrition_analyses.find(params[:id])
  end

  def create
    include_meal_data = params[:include_meal_data] == "1"

    period = case params[:period]
    when "today"
      1
    when "yesterday"
      1
    when "last_week", nil
      7
    else
      7
    end

    offset = period == "today" ? 1 : 0

    summary_service = NutritionSummaryService.new(Current.user, period:, offset:)

    analysis = NutritionAnalysis.create!(
      user: Current.user,
      text: "Analysis in progress...",
      date_start: summary_service.start_date,
      date_end: summary_service.end_date,
      executed_at: Time.current,
      include_meal_data: include_meal_data,
      period: period,
      status: "pending"
    )

    # Queue job with analysis ID
    AnalyzeNutritionJob.perform_later(
      user_id: Current.user.id,
      summary_data: summary_service.summary_data,
      analysis_id: analysis.id,
      user_meals_ids: include_meal_data ? summary_service.user_meals.map { |user_meal| user_meal.id  } : nil
    )

    redirect_to analyses_path, notice: "Analysis job has been queued. It will update automatically when complete."
  end
end
