module UserMealTimeline
  extend ActiveSupport::Concern

  def build_user_meal(meal: nil, meal_id: nil, consumed_at: nil, date: nil)
    consumed_at ||= if date.present?
      parsed_date = Date.parse(date)
      parsed_date == user_today ? Time.current : parsed_date.in_time_zone.end_of_day
    else
      Time.current
    end

    attrs = { consumed_at: consumed_at }
    attrs[:meal] = meal if meal
    attrs[:meal_id] = meal_id if meal_id
    user_meals.build(attrs)
  end

  def user_meals_on_date(date)
    start_of_day = date.in_time_zone.beginning_of_day
    end_of_day = date.in_time_zone.end_of_day
    user_meals.where(consumed_at: start_of_day..end_of_day).order(consumed_at: :desc)
  end

  def user_today
    Time.current.to_date
  end

  def user_date_is_today?(user_date)
    user_today == Date.parse(user_date)
  end

  def relative_date_label(date)
    today = user_today
    case date
    when today
      "Today"
    when today - 1.day
      "Yesterday"
    when today + 1.day
      "Tomorrow"
    else
      date
    end
  end

  def user_meals_in_date_range(start_date, end_date)
    start_datetime = Time.zone.local(start_date.year, start_date.month, start_date.day, 0, 0, 0)
    end_datetime = Time.zone.local(end_date.year, end_date.month, end_date.day, 23, 59, 59)

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
end
