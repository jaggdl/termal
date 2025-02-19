class UserMeal < ApplicationRecord
  belongs_to :user
  belongs_to :meal

  validates :consumed_at, presence: true

  # after_commit :broadcast_user_meal

  def consumed_at_in_timezone
    consumed_at.in_time_zone(Current.user_profile.timezone)
  end

  def broadcast_user_meal
    date = consumed_at_in_timezone.to_date

    broadcast_replace_to(
      [user, "user_meals"],
      target: "meal-#{meal.id}",
      partial: "user_meals/meal_info",
      locals: { user_meal: self }
    )

    broadcast_replace_to(
      [user, "user_meals"],
      target: "nutrient-meters-#{date.to_s}",
      partial: "shared/nutrient_meters",
      locals: { user_meals: user.user_meals_on_date(date), date: date }
    )
  end
end
