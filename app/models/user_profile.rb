class UserProfile < ApplicationRecord
  belongs_to :user

  validates :user_id, uniqueness: true

  delegate :daily_targets, to: :nutrition_calculator

  private

  def nutrition_calculator
    @nutrition_calculator ||= NutritionCalculator.new(self)
  end
end
