class Meal < ApplicationRecord
  belongs_to :user
  has_one_attached :image

  def consumed_at_in_timezone(timezone)
    consumed_at.in_time_zone(timezone)
  end
end
