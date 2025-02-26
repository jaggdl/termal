class NutritionSummaryController < ApplicationController
  def show
    # Get period from params or default to 7 days
    @period = (params[:period] || "7").to_i

    # Get the user's timezone
    user_timezone = Current.user_profile.timezone
    tz = ActiveSupport::TimeZone[user_timezone]

    # Calculate the start date based on the period
    @end_date = Time.current.in_time_zone(tz).to_date
    @start_date = @end_date - (@period - 1).days

    # Get all user meals in the period
    start_datetime = tz.local(@start_date.year, @start_date.month, @start_date.day, 0, 0, 0)
    end_datetime = tz.local(@end_date.year, @end_date.month, @end_date.day, 23, 59, 59)

    @user_meals = Current.user.user_meals
                          .includes(:meal)
                          .where(consumed_at: start_datetime..end_datetime)
                          .order(consumed_at: :asc)

    # Initialize data arrays for charts
    @dates = []
    @calories = []
    @proteins = []
    @fats = []
    @carbs = []

    # Get daily targets
    @daily_targets = Current.user_profile.daily_targets

    # Group meals by date and calculate daily totals
    meal_data_by_date = {}

    # Initialize all dates in the range with zero values
    (@start_date..@end_date).each do |date|
      formatted_date = date.strftime("%b %d")
      @dates << formatted_date
      meal_data_by_date[formatted_date] = {
        calories: 0,
        proteins: 0,
        fats: 0,
        carbs: 0,
        date: date
      }
    end

    # Populate with actual data
    @user_meals.each do |user_meal|
      meal_date = user_meal.consumed_at_in_timezone.to_date
      formatted_date = meal_date.strftime("%b %d")

      # Skip if outside our date range
      next unless meal_data_by_date[formatted_date]

      meal_data_by_date[formatted_date][:calories] += (user_meal.meal.calories || 0)
      meal_data_by_date[formatted_date][:proteins] += (user_meal.meal.proteins || 0)
      meal_data_by_date[formatted_date][:fats] += (user_meal.meal.fats || 0)
      meal_data_by_date[formatted_date][:carbs] += (user_meal.meal.carbs || 0)
    end

    # Convert to arrays for charting
    @dates.each do |date|
      @calories << meal_data_by_date[date][:calories]
      @proteins << meal_data_by_date[date][:proteins].round(1)
      @fats << meal_data_by_date[date][:fats].round(1)
      @carbs << meal_data_by_date[date][:carbs].round(1)
    end

    # Calculate averages
    @avg_calories = @calories.sum / @period
    @avg_proteins = @proteins.sum / @period
    @avg_fats = @fats.sum / @period
    @avg_carbs = @carbs.sum / @period

    # Calculate percentage of target
    @avg_calories_pct = (@avg_calories / @daily_targets[:calories] * 100).round
    @avg_proteins_pct = (@avg_proteins / @daily_targets[:proteins] * 100).round
    @avg_fats_pct = (@avg_fats / @daily_targets[:fats] * 100).round
    @avg_carbs_pct = (@avg_carbs / @daily_targets[:carbs] * 100).round
  end
end

