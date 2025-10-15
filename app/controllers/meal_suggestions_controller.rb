class MealSuggestionsController < ApplicationController
  def index
    @date = params[:date]&.to_date || Date.current
    @suggestion_sets = generate_meal_sets

    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def generate_meal_sets
    daily_targets = Current.user_profile.daily_targets
    remaining_nutrients = calculate_remaining_nutrients(daily_targets)

    candidate_meals = fetch_candidate_meals(remaining_nutrients)

    return [] if candidate_meals.empty?

    3.times.map do |index|
      {
        meals: select_optimal_meal_set(candidate_meals, remaining_nutrients, index),
        set_number: index + 1
      }
    end
  end

  def fetch_candidate_meals(remaining_nutrients)
    max_calories_per_meal = remaining_nutrients[:calories] * 0.5
    min_calories_per_meal = remaining_nutrients[:calories] * 0.1

    Meal.where("calories BETWEEN ? AND ?", min_calories_per_meal, max_calories_per_meal)
        .order("RANDOM()")
        .limit(50)
  end

  def select_optimal_meal_set(candidate_meals, remaining_nutrients, seed)
    target_per_meal = {
      calories: remaining_nutrients[:calories] / 3.0,
      proteins: remaining_nutrients[:proteins] / 3.0,
      carbs: remaining_nutrients[:carbs] / 3.0,
      fats: remaining_nutrients[:fats] / 3.0
    }

    meals_with_scores = candidate_meals.map do |meal|
      score = calculate_meal_score(meal, target_per_meal)
      { meal: meal, score: score }
    end

    meals_with_scores.shuffle(random: Random.new(seed))
                     .sort_by { |m| -m[:score] }
                     .first(5)
                     .map { |m| m[:meal] }
  end

  def calculate_meal_score(meal, target)
    calorie_diff = (meal.calories - target[:calories]).abs / target[:calories].to_f
    protein_diff = (meal.proteins - target[:proteins]).abs / target[:proteins].to_f
    carb_diff = (meal.carbs - target[:carbs]).abs / target[:carbs].to_f
    fat_diff = (meal.fats - target[:fats]).abs / target[:fats].to_f

    total_diff = calorie_diff + protein_diff + carb_diff + fat_diff

    1.0 / (1.0 + total_diff)
  end

  def calculate_remaining_nutrients(daily_targets)
    consumed = consumed_nutrients_for_date(@date)

    {
      calories: [ daily_targets[:calories] - consumed[:calories], 0 ].max,
      proteins: [ daily_targets[:proteins] - consumed[:proteins], 0 ].max,
      carbs: [ daily_targets[:carbs] - consumed[:carbs], 0 ].max,
      fats: [ daily_targets[:fats] - consumed[:fats], 0 ].max
    }
  end

  def consumed_nutrients_for_date(date)
    user_meals = Current.user.user_meals_on_date(date).includes(:meal)

    {
      calories: user_meals.sum { |um| um.meal&.calories || 0 },
      proteins: user_meals.sum { |um| um.meal&.proteins || 0 },
      carbs: user_meals.sum { |um| um.meal&.carbs || 0 },
      fats: user_meals.sum { |um| um.meal&.fats || 0 }
    }
  end
end
