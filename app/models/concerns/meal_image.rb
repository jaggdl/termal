module MealImage
  extend ActiveSupport::Concern

  included do
    has_one_attached :image
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
      .convert("png")
      .call
  end

  def convert_to_base64_with_mime(image)
    encoded_image = Base64.strict_encode64(image.read)
    "data:image/png;base64,#{encoded_image}"
  end
end