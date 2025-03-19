class ProcessMealImageJob < ApplicationJob
  queue_as :default

  def perform(user_meal_id, prompt)
    user_meal = UserMeal.find(user_meal_id)
    meal = user_meal.meal

    begin
      get_meal_data(meal, prompt)
      user_meal.update(error: nil)
    rescue => e
      if e.is_a?(Faraday::UnauthorizedError)
        handle_error(user_meal, :invalid_openai_api_key)
      else
        Rails.logger.error("Meal processing error: #{e.message}")
        handle_error(user_meal, :server_error)
      end
    ensure
      user_meal.broadcast_user_meal
    end
  end

  private

  def get_meal_data(meal, prompt)
    llm_service = LlmService.new
    llm_service.analyze_meal_image(meal)
  end

  def handle_error(user_meal, error_code)
    user_meal.update(error: error_code.to_s)

    error_message = UserMeal.error_message_for(error_code)

    user_meal.broadcast_replace_to(
      [ user_meal.user, "user_meals" ],
      target: "flash",
      partial: "shared/flash",
      locals: { flash: { alert: error_message } }
    )
  end
end
