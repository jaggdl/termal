class UserMeal < ApplicationRecord
  include ErrorMessages

  belongs_to :user
  belongs_to :meal

  validates :consumed_at, presence: true

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
end
