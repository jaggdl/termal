class ProcessMealImageJob < ApplicationJob
  queue_as :default

  def perform(user_meal_id)
    user_meal = UserMeal.find(user_meal_id)
    meal = user_meal.meal

    begin
      meal_data = get_meal_data(meal)
      meal.update(meal_data)
      user_meal.update(error: nil)  # This line is reached only if no error is raised
    rescue => e
      Rails.logger.error("Meal processing error: #{e.message}")
      error_code = determine_error_code(e)
      handle_error(user_meal, error_code)
    ensure
      user_meal.broadcast_user_meal
    end
  end

  private

  def get_meal_data(meal)
    LlmService.new.analyze_meal(meal)
  end

  def determine_error_code(error)
    message = error.message.downcase
    if message.include?("quota") || message.include?("rate limit")
      :quota_exceeded
    else
      :server_error
    end
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
