class UserMeal < ApplicationRecord
  include ErrorMessages

  belongs_to :user
  belongs_to :meal

  validates :consumed_at, presence: true
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }, allow_nil: true
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, allow_nil: true
  validate :both_coordinates_present_or_absent

  def consumed_at_in_timezone
    consumed_at.in_time_zone
  end

  def date_consumed
    consumed_at_in_timezone.to_date
  end

  def time_consumed
    consumed_at_in_timezone.to_time
  end

  def broadcast_user_meal
    broadcast_replace_to(
      [ user, "user_meals" ],
      target: "user-meal-#{id}",
      partial: "user_meals/meal_info",
      locals: { user_meal: self }
    )

    broadcast_replace_to(
      [ user, "user_meals" ],
      target: "nutrient-meters-#{date_consumed}",
      partial: "shared/nutrient_meters",
      locals: { user_meals: user.user_meals_on_date(date_consumed), date: date_consumed, user_profile: user.user_profile }
    )
  end

  def has_location?
    latitude.present? && longitude.present?
  end

  def period
    MealPeriod.for_hour(consumed_at_in_timezone.hour)
  end

  def self.create_from_params(user:, date:, prompt:, files:, latitude: nil, longitude: nil)
    user_meal = user.build_user_meal(date: date)
    user_meal.latitude = latitude if latitude.present?
    user_meal.longitude = longitude if longitude.present?

    meal = user_meal.build_meal(prompt: prompt)
    meal.user = user
    meal.images.attach(files) if files.present?

    user_meal.tap do |um|
      if um.save
        um.process_meal_image_later
      end
    end
  end

  def retry_processing!
    update!(error: nil)
    process_meal_image_later
  end

  def process_meal_image_later
    ProcessMealImageJob.perform_later(id)
  end

  delegate :label, :icon, to: :period, prefix: true, allow_nil: true

  private

  def both_coordinates_present_or_absent
    if latitude.present? ^ longitude.present?
      errors.add(:base, "Both latitude and longitude must be present or both must be absent")
    end
  end
end
