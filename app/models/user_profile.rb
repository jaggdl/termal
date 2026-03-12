class UserProfile < ApplicationRecord
  include FitnessOptions

  belongs_to :user

  validates :user_id, uniqueness: true

  enum :physical_activity, PHYSICAL_ACTIVITIES.keys.index_with(&:to_s), prefix: true
  enum :muscle_building, MUSCLE_GOALS.keys.index_with(&:to_s), prefix: true

  delegate :daily_targets, to: :nutrition_calculator

  def profile_completed?
    age.present? &&
      sex.present? &&
      weight.present? &&
      height.present? &&
      physical_activity.present? &&
      weight_goals.present? &&
      muscle_building.present?
  end

  def meal_nutrient_percentage(meal, nutrient_name)
    daily_target = daily_targets[nutrient_name.to_sym]
    ((meal[nutrient_name].to_f / daily_target) * 100).round
  end

  private

  def nutrition_calculator
    @nutrition_calculator ||= NutritionCalculator.new(self)
  end
end
