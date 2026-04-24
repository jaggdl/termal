class UserMeal < ApplicationRecord
  include ErrorMessages

  belongs_to :user
  belongs_to :meal

  validates :consumed_at, presence: true
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }, allow_nil: true
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, allow_nil: true
  validate :both_coordinates_present_or_absent

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

  def update_consumed_at(datetime: nil, date: nil, time: nil)
    tz = ActiveSupport::TimeZone[user.user_profile.timezone]

    new_consumed_at = if datetime.present?
      tz.parse(datetime)
    elsif date.present? && time.present?
      parsed_date = Date.parse(date)
      time_parts = time.split(":").map(&:to_i)
      hour = time_parts[0] || 0
      minute = time_parts[1] || 0
      second = time_parts[2] || 0
      tz.local(parsed_date.year, parsed_date.month, parsed_date.day, hour, minute, second)
    elsif date.present?
      parsed_date = Date.parse(date)
      tz.local(parsed_date.year, parsed_date.month, parsed_date.day, 23, 59, 59)
    end

    update(consumed_at: new_consumed_at) if new_consumed_at
  end

  private

  def both_coordinates_present_or_absent
    if latitude.present? ^ longitude.present?
      errors.add(:base, "Both latitude and longitude must be present or both must be absent")
    end
  end
end
