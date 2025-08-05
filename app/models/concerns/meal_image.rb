module MealImage
  extend ActiveSupport::Concern

  included do
    has_one_attached :image
    has_many_attached :images
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

  def primary_image
    image.attached? ? image : images.first
  end

  def all_images
    images_array = []
    images_array << image if image.attached?
    images_array += images.to_a if images.attached?
    images_array.uniq
  end

  def image_paths
    all_images.filter_map do |img|
      ActiveStorage::Blob.service.send(:path_for, img.key)
    end
  end

  def base64_images
    all_images.map do |img|
      resized_image = resize_and_convert_image_for(img)
      convert_to_base64_with_mime(resized_image)
    end.compact
  end

  def primary_base64_image
    img = primary_image
    return nil unless img&.attached?

    resized_image = resize_and_convert_image_for(img)
    convert_to_base64_with_mime(resized_image)
  end

  private

  def resize_and_convert_image
    resize_and_convert_image_for(image)
  end

  def resize_and_convert_image_for(img)
    img_path = ActiveStorage::Blob.service.send(:path_for, img.key)
    ImageProcessing::Vips
      .source(img_path)
      .resize_to_limit(1000, 1000)
      .convert("png")
      .call
  end

  def convert_to_base64_with_mime(image)
    encoded_image = Base64.strict_encode64(image.read)
    "data:image/png;base64,#{encoded_image}"
  end
end
