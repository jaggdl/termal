class MealSuggestionsService
  def initialize(user:, date:)
    @user = user
    @date = date
    @user_profile = user.user_profile
  end

  def generate_suggestions
    daily_targets = @user_profile.daily_targets
    remaining_nutrients = calculate_remaining_nutrients(daily_targets)

    candidate_meals = fetch_candidate_meals(remaining_nutrients)

    return nil if candidate_meals.values.all?(&:empty?)

    llm_response = generate_suggestions_with_llm(candidate_meals, remaining_nutrients)

    meal_ids = llm_response["meal_set"]["meal_ids"]
    meals = Meal.where(id: meal_ids).index_by(&:id)

    {
      meals: meal_ids.map { |id| meals[id] }.compact
    }
  end

  private

  def generate_suggestions_with_llm(candidate_meals, remaining_nutrients)
    prompt = build_meal_suggestions_prompt(candidate_meals, remaining_nutrients)

    llm_service = LlmService.new
    chat = RubyLLM.chat(model: "o4-mini")
    chat.with_schema(Schema::MealSuggestions)

    response = chat.ask(prompt)

    response.content
  end

  def build_meal_suggestions_prompt(candidate_meals, remaining_nutrients)
    low_calorie_data = format_meals_data(candidate_meals[:low])
    medium_calorie_data = format_meals_data(candidate_meals[:medium])
    high_calorie_data = format_meals_data(candidate_meals[:high])

    <<~PROMPT
      You are a nutrition assistant helping to suggest meal combinations for the rest of the day.

      Remaining daily nutrition targets:
      - Calories: #{remaining_nutrients[:calories]}
      - Proteins: #{remaining_nutrients[:proteins]}g
      - Carbs: #{remaining_nutrients[:carbs]}g
      - Fats: #{remaining_nutrients[:fats]}g

      Available meals are grouped by calorie level:

      LOW CALORIE MEALS:
      #{low_calorie_data}

      MEDIUM CALORIE MEALS:
      #{medium_calorie_data}

      HIGH CALORIE MEALS:
      #{high_calorie_data}

      Generate 1 meal set that contains the meal IDs that work well together to meet the remaining nutrition targets.

      Consider:
      - Nutritional balance across the meals in the set
      - Variety in meal types and calorie levels
      - Meeting (but not significantly exceeding) the remaining targets
      - Mix meals from different calorie groups for better variety
    PROMPT
  end

  def format_meals_data(meals)
    return "None available" if meals.empty?

    meals.map do |meal|
      "ID: #{meal.id}, Name: #{meal.meal_name}, Calories: #{meal.calories}, Proteins: #{meal.proteins}g, Carbs: #{meal.carbs}g, Fats: #{meal.fats}g"
    end.join("\n")
  end

  def fetch_candidate_meals(remaining_nutrients)
    base_query = Meal.joins(:user_meals)
                     .where(user_meals: { user_id: @user.id })
                     .group("meals.id")
                     .order("COUNT(user_meals.id) DESC")

    remaining_cals = remaining_nutrients[:calories]

    {
      low: base_query.where("meals.calories BETWEEN ? AND ?", remaining_cals * 0.1, remaining_cals * 0.4).limit(20),
      medium: base_query.where("meals.calories BETWEEN ? AND ?", remaining_cals * 0.3, remaining_cals * 0.7).limit(20),
      high: base_query.where("meals.calories BETWEEN ? AND ?", remaining_cals * 0.6, remaining_cals * 1.1).limit(20)
    }
  end

  def calculate_remaining_nutrients(daily_targets)
    consumed = consumed_nutrients_for_date

    {
      calories: [ daily_targets[:calories] - consumed[:calories], 0 ].max,
      proteins: [ daily_targets[:proteins] - consumed[:proteins], 0 ].max,
      carbs: [ daily_targets[:carbs] - consumed[:carbs], 0 ].max,
      fats: [ daily_targets[:fats] - consumed[:fats], 0 ].max
    }
  end

  def consumed_nutrients_for_date
    user_meals = @user.user_meals_on_date(@date)

    {
      calories: user_meals.sum { |um| um.meal.calories || 0 },
      proteins: user_meals.sum { |um| um.meal.proteins || 0 },
      carbs: user_meals.sum { |um| um.meal.carbs || 0 },
      fats: user_meals.sum { |um| um.meal.fats || 0 }
    }
  end
end
