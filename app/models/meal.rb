class Meal < ApplicationRecord
  include VectorSearch

  has_many :user_meals, dependent: :destroy
  has_many :users, through: :user_meals
  has_one_attached :image

  def created_at_in_timezone
    created_at.in_time_zone(Current.user_profile.timezone)
  end

  def image_path
    if image.attached?
      ActiveStorage::Blob.service.send(:path_for, image.key)
    else
      nil
    end
  end
end
