class ProcessMealImageJob < ApplicationJob
  queue_as :default

  def perform(user_meal_id, prompt)
    user_meal = UserMeal.find(user_meal_id)
    meal = user_meal.meal

    begin
      openai_service = OpenAiService.new
      meal_data = nil

      if meal.image.attached?
        base64_image_url = process_image(meal.image)
        meal_data = openai_service.analyze_meal_image(base64_image_url, prompt)
      else
        meal_data = openai_service.analyze_meal_text(prompt)
      end

      if meal_data
        meal.update(meal_data)
        user_meal.update(error: nil)
        user_meal.broadcast_user_meal
      else
        handle_error(user_meal, :failed_meal_analysis)
      end
    rescue => e
      if e.is_a?(Faraday::UnauthorizedError)
        handle_error(user_meal, :invalid_openai_api_key)
      else
        Rails.logger.error("Meal processing error: #{e.message}")
        handle_error(user_meal, :server_error)
      end
    end
  end

  private

  def handle_error(user_meal, error_code)
    user_meal.update(error: error_code.to_s)
    user_meal.broadcast_user_meal

    error_message = UserMeal.error_message_for(error_code)

    user_meal.broadcast_replace_to(
      [ user_meal.user, "user_meals" ],
      target: "flash",
      partial: "shared/flash",
      locals: { flash: { alert: error_message } }
    )
  end

  def process_image(meal_image)
    image_data = meal_image.download
    Rails.logger.info("Image data size: #{image_data.size}")

    # Create a temporary file and write the image data to it
    temp_file = Tempfile.new([ "meal_image", ".jpg" ], binmode: true)
    temp_file.write(image_data)
    temp_file.rewind

    begin
      resized_image = resize_and_convert_image(temp_file.path)
      convert_to_base64_with_mime(resized_image)
    rescue => e
      Rails.logger.error("Failed to process image: #{e.message}")
      Rails.logger.error("Error backtrace: #{e.backtrace.join("\n")}")
      # Instead of raising the original error, raise a custom error with a specific code
      # that will be caught by the main rescue block
      raise StandardError.new(:image_processing_error)
    ensure
      temp_file.close
      temp_file.unlink # Ensure the temp file is deleted
    end
  end

  def resize_and_convert_image(image_path)
    ImageProcessing::Vips
      .source(image_path)
      .resize_to_limit(1000, 1000)
      .convert("png")  # Converts to PNG
      .call
  end

  def convert_to_base64_with_mime(image)
    encoded_image = Base64.strict_encode64(File.read(image.path))
    "data:image/png;base64,#{encoded_image}"
  end
end
