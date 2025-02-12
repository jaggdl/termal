class ProcessMealImageJob < ApplicationJob
  queue_as :default

  def perform(meal_id, base_64_image_url, prompt)
    meal = Meal.find(meal_id)
    meal_data = process_meal_image(base_64_image_url, prompt)
    if meal_data
      meal.update(
        meal_name: meal_data[:meal_name],
        calories: meal_data[:calories],
        fats: meal_data[:fats],
        proteins: meal_data[:proteins],
        carbs: meal_data[:carbs],
        fiber: meal_data[:fiber],
        sodium: meal_data[:sodium],
        sugar: meal_data[:sugar],
        cholesterol: meal_data[:cholesterol],
      )
    else
      Rails.logger.error("Failed to process meal image for meal ID: #{meal_id}")
    end
  end

  private

  def process_meal_image(base64_image, prompt)
    openai_service = OpenAiService.new
    openai_service.analyze_meal_image(base64_image, prompt)
  end
end
