class AnalyzeNutritionJob < ApplicationJob
  queue_as :default

  def perform(user_id:, user_meals_ids:, summary_data:, analysis_id: nil)
    user = User.find_by(id: user_id)
    analysis = NutritionAnalysis.find_by(id: analysis_id)

    llm_service = LlmService.new

    user_profile = user.user_profile

    meal_data = collect_meal_details(user_meals_ids)

    analysis_text = llm_service.analyze_nutrition(user_profile:, summary_data:, meal_data:)

    analysis.update!(
      text: analysis_text,
      status: "completed"
    )

    user.send_push_notification(
      title: "Nutrition Analysis Complete",
      message: "Your nutrition analysis is ready to view!",
      path: "/analysis/#{analysis.id}",
      icon: "/icon.png"
    )
  rescue StandardError => e
    Rails.logger.error("Error in AnalyzeNutritionJob for user #{user_id}: #{e.message}")
    analysis.update(text: "An error occurred while generating your analysis. Please try again.", status: "error")
  end

  private

  def collect_meal_details(user_meals_ids)
    user_meals = UserMeal.find(user_meals_ids)

    user_meals.map do |user_meal|
      {
        date: user_meal.date_consumed,
        time: user_meal.time_consumed,
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
