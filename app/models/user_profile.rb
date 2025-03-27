class UserProfile < ApplicationRecord
  belongs_to :user

  validates :user_id, uniqueness: true

  delegate :daily_targets, to: :nutrition_calculator

  def meal_nutrient_percentage(meal, nutrient_name)
    daily_target = daily_targets[nutrient_name.to_sym]
    ((meal[nutrient_name].to_f / daily_target) * 100).round
  end

  private

  def nutrition_calculator
    @nutrition_calculator ||= NutritionCalculator.new(self)
  end
end
