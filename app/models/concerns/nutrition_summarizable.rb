module NutritionSummarizable
  extend ActiveSupport::Concern

  NUTRIENTS = [ :calories, :proteins, :fats, :carbs ]

  def nutrition_summary(period: 7, offset: 0, query: nil, selected_meal_ids: nil)
    NutritionSummary.new(self, period: period, offset: offset, query: query, selected_meal_ids: selected_meal_ids)
  end

  class NutritionSummary
    attr_reader :user, :period, :start_date, :end_date, :query, :selected_meal_ids

    def initialize(user, period: 7, offset: 0, query: nil, selected_meal_ids: nil)
      @user = user
      @period = period
      @query = query
      @selected_meal_ids = selected_meal_ids
      @end_date = Time.current.to_date - offset.days
      @start_date = @end_date - (@period - 1).days
    end

    def data
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
      @user_meals ||= begin
        meals = user.user_meals_in_date_range(start_date, end_date)

        if query.present?
          matching_meal_ids = vector_search_meal_ids

          if selected_meal_ids.present?
            matching_meal_ids = matching_meal_ids & selected_meal_ids.map(&:to_i)
          end

          meals = meals.joins(:meal).where(meals: { id: matching_meal_ids })
        end

        meals
      end
    end

    def matching_meals
      return [] if query.blank?

      meal_ids = vector_search_meal_ids
      return [] if meal_ids.empty?

      Meal
        .joins(:user_meals)
        .where(user_meals: { user_id: user.id, consumed_at: start_date.beginning_of_day..end_date.end_of_day })
        .where(id: meal_ids)
        .select("meals.*, COUNT(user_meals.id) as consumption_count")
        .group("meals.id")
        .order("consumption_count DESC, meals.meal_name ASC")
    end

    def vector_search_meal_ids
      return [] if query.blank?

      query_embedding = QueryEmbedding.find_or_create_embedding(query)
      embedding = query_embedding.embedding

      user_meal_ids = user.user_meals_in_date_range(start_date, end_date).pluck(:meal_id).uniq
      return [] if user_meal_ids.empty?

      vector_sql = <<~SQL
        SELECT meal_id, distance
        FROM meal_vectors
        WHERE embedding MATCH ? AND k = ?
      SQL

      vector_results = MealVector.find_by_sql([
        vector_sql,
        embedding.to_s,
        [ user_meal_ids.length, 100 ].max
      ])

      vector_results
        .select { |vr| user_meal_ids.include?(vr.meal_id) && vr.distance <= 0.7 }
        .map(&:meal_id)
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
      today = Time.current.to_date
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
end
