module UserMealTimeline
  extend ActiveSupport::Concern

  delegate :timezone, to: :user_profile

  def user_meals_on_date(date)
    start_of_day = date.in_time_zone(timezone).beginning_of_day
    end_of_day = date.in_time_zone(timezone).end_of_day
    user_meals.where(consumed_at: start_of_day..end_of_day).order(consumed_at: :desc)
  end

  def user_today
    Time.now.in_time_zone(timezone).to_date
  end

  def user_date_is_today?(user_date)
    user_today == Date.parse(user_date)
  end

  def user_meals_in_date_range(start_date, end_date)
    time_zone = ActiveSupport::TimeZone[timezone]
    start_datetime = time_zone.local(start_date.year, start_date.month, start_date.day, 0, 0, 0)
    end_datetime = time_zone.local(end_date.year, end_date.month, end_date.day, 23, 59, 59)

    user_meals
      .includes(:meal)
      .where(consumed_at: start_datetime..end_datetime)
      .order(consumed_at: :asc)
  end

  def group_meals_by_date(meals)
    meals.group_by { |um| um.date_consumed }
  end
end
