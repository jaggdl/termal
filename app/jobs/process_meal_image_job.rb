class ProcessMealImageJob < ApplicationJob
  queue_as :default

  def perform(user_meal_id, prompt)
    user_meal = UserMeal.find(user_meal_id)
    meal = user_meal.meal

    openai_service = OpenAiService.new
    meal_data = nil

    # Check if an image is attached
    if meal.image.attached?
      base64_image_url = process_image(meal.image)
      meal_data = openai_service.analyze_meal_image(base64_image_url, prompt)
    else
      # Process the meal based on text prompt only
      meal_data = openai_service.analyze_meal_text(prompt)
    end

    if meal_data
      meal.update(
        meal_name: meal_data[:meal_name],
        description: meal_data[:description],
        calories: meal_data[:calories],
        fats: meal_data[:fats],
        proteins: meal_data[:proteins],
        carbs: meal_data[:carbs],
        fiber: meal_data[:fiber],
        sodium: meal_data[:sodium],
        sugar: meal_data[:sugar],
        cholesterol: meal_data[:cholesterol],
      )
      user_meal.broadcast_user_meal
    else
      Rails.logger.error("Failed to analyze meal for user_meal_id: #{user_meal_id}")
    end
  end

  private

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
      raise e
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
