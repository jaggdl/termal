class Meal < ApplicationRecord
  include VectorSearch
  include MealImage

  has_many :user_meals, dependent: :destroy
  has_many :users, through: :user_meals

  def created_at_in_timezone
    created_at.in_time_zone(Current.user_profile.timezone)
  end

  def nutrient_with_unit(attr)
    value = self[attr]
    return nil if value.nil?

    unit = case attr.to_s
    when "calories"
             ""
    else
             "g"
    end

    "#{value}#{unit}"
  end
end
