class NutritionAnalysesController < ApplicationController
  def index
    @analyses = Current.user.nutrition_analyses.order(executed_at: :desc)
  end

  def show
    @analysis = Current.user.nutrition_analyses.find(params[:id])
  end

  def create
    include_meal_data = params[:include_meal_data] == "1"
    period = params[:period]

    # Create analysis record first with pending status
    period_days = case period
    when "today"
      1
    when "yesterday"
      1
    when "last_week", nil
      7
    else
      7
    end

    summary_service = unless period == "today"
      NutritionSummaryService.new(Current.user, period: period_days, offset: 1)
    else
      NutritionSummaryService.new(Current.user, period: period_days)
    end

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
