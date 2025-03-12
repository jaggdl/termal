module UserMealTimeline
  extend ActiveSupport::Concern

  # Returns user meals for the specified date in user's timezone
  def user_meals_on_date(date)
    timezone = user_profile&.timezone || 'UTC'
    start_of_day = date.in_time_zone(timezone).beginning_of_day
    end_of_day = date.in_time_zone(timezone).end_of_day
    user_meals.where(consumed_at: start_of_day..end_of_day)
  end

  # Returns today's date in the user's timezone
  def user_today
    timezone = user_profile&.timezone || 'UTC'
    Time.now.in_time_zone(timezone).to_date
  end
end