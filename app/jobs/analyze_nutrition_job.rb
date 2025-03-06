class AnalyzeNutritionJob < ApplicationJob
  queue_as :default

  def perform(user_id, include_meal_data = false, period = "last_week")
    user = User.find_by(id: user_id)
    return unless user

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
      NutritionSummaryService.new(user, period: period_days, offset: 1)
    else
      NutritionSummaryService.new(user, period: period_days)
    end
    summary = summary_service.summary_data

    return unless GlobalSetting.get("openai_api_key").present?

    openai_service = OpenAiService.new
    user_profile = user.user_profile

    analysis_data = {
      user_profile: {
        gender: user_profile.sex,
        age: user_profile.age,
        weight: user_profile.weight,
        height: user_profile.height,
        activity_level: user_profile.physical_activity,
        muscle_building: user_profile.muscle_building,
        weight_goals: user_profile.weight_goals,
        daily_targets: user_profile.daily_targets
      },
      nutritional_data: summary,
      period: period
    }

    if include_meal_data
      analysis_data[:meal_details] = collect_meal_details(user, summary_service.start_date, summary_service.end_date)
    end

    analysis_text = openai_service.analyze_nutrition(analysis_data)

    analysis = NutritionAnalysis.create!(
      user: user,
      text: analysis_text,
      date_start: summary_service.start_date,
      date_end: summary_service.end_date,
      executed_at: Time.current,
      include_meal_data: include_meal_data,
      period: period
    )

    user.send_push_notification(
      title: "Nutrition Analysis Complete",
      message: "Your #{period.gsub('_', ' ')} nutrition analysis is ready to view!",
      path: "/analysis/#{analysis.id}",
      icon: "/icon.png"
    )
  rescue StandardError => e
    Rails.logger.error("Error in AnalyzeNutritionJob for user #{user_id}: #{e.message}")
  end

  private

  def collect_meal_details(user, start_date, end_date)
    timezone = ActiveSupport::TimeZone[user.user_profile.timezone]
    start_datetime = timezone.local(start_date.year, start_date.month, start_date.day, 0, 0, 0)
    end_datetime = timezone.local(end_date.year, end_date.month, end_date.day, 23, 59, 59)

    user_meals = user.user_meals
      .includes(:meal)
      .where(consumed_at: start_datetime..end_datetime)
      .order(consumed_at: :asc)

    user_meals.map do |user_meal|
      date_obj = user_meal.consumed_at_in_timezone.to_date
      {
        date: user_meal.consumed_at_in_timezone.strftime("%b %d, %Y"),
        date_param: date_obj.strftime("%Y-%m-%d"),
        time: user_meal.consumed_at_in_timezone.strftime("%I:%M %p"),
        meal_name: user_meal.meal.meal_name,
        description: user_meal.meal.description,
        calories: user_meal.meal.calories,
        proteins: user_meal.meal.proteins,
        carbs: user_meal.meal.carbs,
        fats: user_meal.meal.fats,
        meal_id: user_meal.meal.id,
        user_meal_id: user_meal.id
      }
    end
  end
end
