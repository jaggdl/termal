class NutritionSummaryService
  NUTRIENTS = [ :calories, :proteins, :fats, :carbs ]

  attr_reader :user, :period, :start_date, :end_date, :timezone

  def initialize(user, period: 7, offset: 0)
    @user = user
    @period = period
    @timezone = ActiveSupport::TimeZone[user.timezone]
    @end_date = Time.current.in_time_zone(timezone).to_date - offset.days
    @start_date = @end_date - (@period - 1).days
  end

  def summary_data
    daily_targets = user.user_profile.daily_targets
    meal_data = build_meal_data
    averages = calculate_averages(meal_data)
    percentages = calculate_percentages(averages, daily_targets)

    {
      chart_data: {
        dates: meal_data.map { |data| data[:date_formatted] },
        nutrients: NUTRIENTS.map { |nutrient| [ nutrient, meal_data.map { |data| data[nutrient] } ] }.to_h,
        targets: daily_targets.slice(*NUTRIENTS),
        averages: averages
      },
      daily_targets: daily_targets,
      averages: averages,
      percentages: percentages,
      period: period,
      start_date: start_date,
      end_date: end_date
    }
  end

  def user_meals
    @user_meals ||= user.user_meals_in_date_range(start_date, end_date)
  end

  private

  def build_meal_data
    meals_by_date = user.group_meals_by_date(user_meals)

    (start_date..end_date).map do |date|
      meals = meals_by_date[date] || []
      totals = NUTRIENTS.each_with_object({}) do |nutrient, hash|
        hash[nutrient] = meals.sum { |um| um.meal.send(nutrient) || 0 }
      end
      {
        date: date,
        date_formatted: date.strftime("%b %d"),
        date_param: date.strftime("%Y-%m-%d")
      }.merge(totals)
    end
  end

  def calculate_averages(meal_data)
    today = Time.current.in_time_zone(timezone).to_date
    valid_days = meal_data.select do |d|
      (d[:date] != today || @period == 1) &&
      NUTRIENTS.any? { |nutrient| d[nutrient] > 0 }
    end

    return NUTRIENTS.map { |n| [ n, 0 ] }.to_h if valid_days.empty?

    valid_days_count = valid_days.size
    NUTRIENTS.each_with_object({}) do |nutrient, hash|
      sum = valid_days.sum { |d| d[nutrient] }
      hash[nutrient] = sum.fdiv(valid_days_count)
    end
  end

  def calculate_percentages(averages, daily_targets)
    NUTRIENTS.each_with_object({}) do |nutrient, hash|
      target = daily_targets[nutrient]
      hash[nutrient] = target && target > 0 ? (averages[nutrient].fdiv(target) * 100).round : 0
    end
  end
end
