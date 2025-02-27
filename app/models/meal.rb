class Meal < ApplicationRecord
  has_many :user_meals, dependent: :destroy
  has_many :users, through: :user_meals
  has_one_attached :image

  def created_at_in_timezone
    created_at.in_time_zone(Current.user_profile.timezone)
  end
end
