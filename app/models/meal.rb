class Meal < ApplicationRecord
  include VectorSearch
  include MealImage
  include MealSearch

  belongs_to :user
  has_many :user_meals, dependent: :destroy

  def created_at_in_timezone
    created_at.in_time_zone
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
