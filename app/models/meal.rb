class Meal < ApplicationRecord
  include VectorSearch

  has_many :user_meals, dependent: :destroy
  has_many :users, through: :user_meals
  has_one_attached :image

  def created_at_in_timezone
    created_at.in_time_zone(Current.user_profile.timezone)
  end

  def image_path
    return nil unless image.attached?
    ActiveStorage::Blob.service.send(:path_for, image.key)
  end

  def base64_image
    return nil unless image.attached?

    resized_image = resize_and_convert_image
    convert_to_base64_with_mime(resized_image)
  end

  private

  def resize_and_convert_image
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
