class ProcessMealImageJob < ApplicationJob
  queue_as :default

  def perform(meal_id, prompt)
    meal = Meal.find(meal_id)
    base64_image_url = process_image(meal.image)
    meal_data = analyze_meal_image(base64_image_url, prompt)
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
      meal.broadcast_meal
    else
      Rails.logger.error("No image attached to meal ID: #{meal_id}")
    end
  end

  private

  def process_image(meal_image)
    image_data = meal_image.download
    Rails.logger.info("Image data size: #{image_data.size}")
    Rails.logger.info("Image data first few bytes: #{image_data.byteslice(0, 10).inspect}")
  
    # Create a temporary file and write the image data to it
    temp_file = Tempfile.new(['meal_image', '.jpg'], binmode: true)
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
      .convert('png')  # Converts to PNG
      .call
  end
  
  def convert_to_base64_with_mime(image)
    encoded_image = Base64.strict_encode64(File.read(image.path))
    "data:image/png;base64,#{encoded_image}"
  end

  def analyze_meal_image(base64_image, prompt)
    openai_service = OpenAiService.new
    openai_service.analyze_meal_image(base64_image, prompt)
  end
end
