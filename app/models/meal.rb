class Meal < ApplicationRecord
  belongs_to :user
  has_one_attached :image

  def self.for_date_in_user_timezone(user, date)
  end

  def consumed_at_in_timezone
    consumed_at.in_time_zone(user.user_profile.timezone)
  end

  def meals_of_day
    date = consumed_at_in_timezone.to_date
    timezone = user.user_profile.timezone
    date_in_tz = date.in_time_zone(timezone)
    start_of_day = date_in_tz.beginning_of_day
    end_of_day = date_in_tz.end_of_day

    user.meals.where(consumed_at: start_of_day..end_of_day)
  end

  def broadcast_meal
    date = consumed_at_in_timezone.to_date

    broadcast_replace_to(
      [user, "meals"],
      target: "meal-#{id}",
      partial: "meals/meal_info",
      locals: { meal: self }
    )
    
    broadcast_replace_to(
      [user, "meals"],
      target: "nutrient-meters-#{date.to_s}",
      partial: "shared/nutrient_meters",
      locals: { meals: meals_of_day, date: date }
    )
  end
end
