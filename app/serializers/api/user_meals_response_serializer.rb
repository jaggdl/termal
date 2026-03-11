# frozen_string_literal: true

module Api
  class UserMealsResponseSerializer
    include ActiveModel::Serializers::JSON

    def initialize(date, user_meals)
      @date = date
      @user_meals = user_meals
    end

    def attributes
      {
        "date" => nil,
        "meals" => nil,
        "totals" => nil,
        "targets" => nil,
        "percentages" => nil
      }
    end

    def date
      @date.iso8601
    end

    def meals
      @user_meals.map { |user_meal| UserMealSerializer.new(user_meal) }
    end

    def totals
      @user_meals.each_with_object({
        "calories" => 0,
        "proteins" => 0.0,
        "carbs" => 0.0,
        "fats" => 0.0
      }) do |user_meal, sum|
        meal = user_meal.meal
        sum["calories"] += meal.calories.to_i
        sum["proteins"] += meal.proteins.to_f
        sum["carbs"] += meal.carbs.to_f
        sum["fats"] += meal.fats.to_f
      end
    end

    def targets
      user_profile = ::Current.user.user_profile
      daily_targets = user_profile.daily_targets

      {
        "calories" => daily_targets[:calories],
        "proteins" => daily_targets[:proteins],
        "carbs" => daily_targets[:carbs],
        "fats" => daily_targets[:fats]
      }
    end

    def percentages
      daily_targets = targets
      daily_totals = totals

      {
        "calories" => calculate_percentage(daily_totals["calories"], daily_targets["calories"]),
        "proteins" => calculate_percentage(daily_totals["proteins"], daily_targets["proteins"]),
        "carbs" => calculate_percentage(daily_totals["carbs"], daily_targets["carbs"]),
        "fats" => calculate_percentage(daily_totals["fats"], daily_targets["fats"])
      }
    end

    private

    def calculate_percentage(value, target)
      return 0 if target.nil? || target == 0
      ((value / target.to_f) * 100).round(1)
    end
  end
end
