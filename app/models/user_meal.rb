class UserMeal < ApplicationRecord
  include ErrorMessages

  belongs_to :user
  belongs_to :meal

  validates :consumed_at, presence: true
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }, allow_nil: true
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, allow_nil: true
  validate :both_coordinates_present_or_absent

  def consumed_at=(value)
    if value.is_a?(String) && value.present?
      tz = ActiveSupport::TimeZone[user.user_profile.timezone]
      parsed = Time.parse(value)
      value = tz.local(parsed.year, parsed.month, parsed.day, parsed.hour, parsed.min, parsed.sec)
    end
    super(value)
  rescue ArgumentError
    raise ArgumentError, "Invalid datetime format. Use ISO 8601 format (e.g., 2026-04-24T14:30:00)"
  end

  def consumed_at_in_timezone
    consumed_at.in_time_zone(user.user_profile.timezone)
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

  private

  def both_coordinates_present_or_absent
    if latitude.present? ^ longitude.present?
      errors.add(:base, "Both latitude and longitude must be present or both must be absent")
    end
  end
end
