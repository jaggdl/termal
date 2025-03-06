class NutritionSummaryService
  attr_reader :user, :period, :start_date, :end_date, :timezone

  def initialize(user, period: 7, offset: 0)
    @user = user
    @period = period
    @timezone = ActiveSupport::TimeZone[user.user_profile.timezone]
    @end_date = Time.current.in_time_zone(timezone).to_date - offset.days
    @start_date = @end_date - (@period - 1).days
  end

  def summary_data
    # Get all user meals in the period
    user_meals = fetch_meals

    # Get daily targets
    daily_targets = user.user_profile.daily_targets

    # Group and calculate meal data
    meal_data = process_meal_data(user_meals)

    # Calculate averages and percentages
    averages = calculate_averages(meal_data)
    percentages = calculate_percentages(averages, daily_targets)

    # Return all data needed for the summary view in a more compact structure
    {
      chart_data: {
        dates: meal_data.map { |data| data[:date_formatted] },
        nutrients: {
          calories: meal_data.map { |data| data[:calories] },
          proteins: meal_data.map { |data| data[:proteins] },
          fats: meal_data.map { |data| data[:fats] },
          carbs: meal_data.map { |data| data[:carbs] }
        },
        targets: daily_targets,
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

  private

  def fetch_meals
    start_datetime = timezone.local(start_date.year, start_date.month, start_date.day, 0, 0, 0)
    end_datetime = timezone.local(end_date.year, end_date.month, end_date.day, 23, 59, 59)

    user.user_meals
        .includes(:meal)
        .where(consumed_at: start_datetime..end_datetime)
        .order(consumed_at: :asc)
  end

  def process_meal_data(user_meals)
    # Initialize data hash with zero values for each date
    meal_data = initialize_meal_data_hash

    # Populate with actual data
    user_meals.each do |user_meal|
      meal_date = user_meal.consumed_at_in_timezone.to_date
      formatted_date = meal_date.strftime("%b %d")

      # Skip if outside our date range
      next unless meal_data[formatted_date]

      meal_data[formatted_date][:calories] += (user_meal.meal.calories || 0)
      meal_data[formatted_date][:proteins] += (user_meal.meal.proteins || 0)
      meal_data[formatted_date][:fats] += (user_meal.meal.fats || 0)
      meal_data[formatted_date][:carbs] += (user_meal.meal.carbs || 0)
    end

    # Convert hash to array of values in date order
    meal_data.values
  end

  def initialize_meal_data_hash
    result = {}
    (start_date..end_date).each do |date|
      formatted_date = date.strftime("%b %d")
      result[formatted_date] = {
        date: date,
        date_formatted: formatted_date,
        calories: 0,
        proteins: 0,
        fats: 0,
        carbs: 0
      }
    end
    result
  end

  def calculate_averages(meal_data)
    # Filter out current day and empty days (days with no meals)
    valid_days = meal_data.reject do |d|
      d[:date] == Time.current.in_time_zone(timezone).to_date ||
      (d[:calories] == 0 && d[:proteins] == 0 && d[:fats] == 0 && d[:carbs] == 0)
    end

    # If there are no valid days, return zeros
    return { calories: 0, proteins: 0, carbs: 0, fats: 0 } if valid_days.empty?

    # Calculate averages based on valid days count instead of period
    valid_days_count = valid_days.size
    {
      calories: valid_days.sum { |d| d[:calories] } / valid_days_count,
      proteins: valid_days.sum { |d| d[:proteins] } / valid_days_count,
      carbs: valid_days.sum { |d| d[:carbs] } / valid_days_count,
      fats: valid_days.sum { |d| d[:fats] } / valid_days_count
    }
  end

  def calculate_percentages(averages, daily_targets)
    {
      calories: (averages[:calories] / daily_targets[:calories] * 100).round,
      proteins: (averages[:proteins] / daily_targets[:proteins] * 100).round,
      carbs: (averages[:carbs] / daily_targets[:carbs] * 100).round,
      fats: (averages[:fats] / daily_targets[:fats] * 100).round
    }
  end
end
