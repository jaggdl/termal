module UserMealTimeline
  extend ActiveSupport::Concern

  delegate :timezone, to: :user_profile

  def build_user_meal(meal: nil, meal_id: nil, date: nil, time: nil)
    consumed_at = parse_consumed_at(date, time)
    attrs = { consumed_at: consumed_at }
    attrs[:meal] = meal if meal
    attrs[:meal_id] = meal_id if meal_id
    user_meals.build(attrs)
  end

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

  def daily_nutrition_summaries(start_date, end_date)
    meals = user_meals_in_date_range(start_date, end_date)
    meals_by_date = group_meals_by_date(meals)

    (start_date..end_date).map do |date|
      date_meals = meals_by_date[date] || []

      {
        date: date,
        calories: date_meals.sum { |um| um.meal.calories.to_i },
        proteins: date_meals.sum { |um| um.meal.proteins.to_f },
        carbs: date_meals.sum { |um| um.meal.carbs.to_f },
        fats: date_meals.sum { |um| um.meal.fats.to_f }
      }
    end
  end

  private

  def parse_consumed_at(date_param, time_param)
    tz = ActiveSupport::TimeZone[timezone]
    date = date_param.present? ? Date.parse(date_param) : user_today
    is_today = date == user_today

    if time_param.present?
      time_parts = time_param.split(":").map(&:to_i)
      hour = time_parts[0] || 0
      minute = time_parts[1] || 0
      second = time_parts[2] || 0
      tz.local(date.year, date.month, date.day, hour, minute, second)
    elsif is_today
      Time.now
    else
      tz.local(date.year, date.month, date.day, 23, 59, 59)
    end
  rescue ArgumentError
    raise ArgumentError, "Invalid date or time format"
  end
end
