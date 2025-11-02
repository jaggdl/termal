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

    return [] if candidate_meals.empty?

    llm_response = generate_suggestions_with_llm(candidate_meals, remaining_nutrients)

    llm_response["meal_sets"].map.with_index(1) do |meal_set, index|
      meal_ids = meal_set["meal_ids"]
      meals = Meal.where(id: meal_ids).index_by(&:id)

      {
        meals: meal_ids.map { |id| meals[id] }.compact,
        set_number: index
      }
    end
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
    meals_data = candidate_meals.map do |meal|
      "ID: #{meal.id}, Name: #{meal.meal_name}, Calories: #{meal.calories}, Proteins: #{meal.proteins}g, Carbs: #{meal.carbs}g, Fats: #{meal.fats}g"
    end.join("\n")

    <<~PROMPT
      You are a nutrition assistant helping to suggest meal combinations for the rest of the day.

      Remaining daily nutrition targets:
      - Calories: #{remaining_nutrients[:calories]}
      - Proteins: #{remaining_nutrients[:proteins]}g
      - Carbs: #{remaining_nutrients[:carbs]}g
      - Fats: #{remaining_nutrients[:fats]}g

      Available meals:
      #{meals_data}

      Generate 3 different meal sets. Each set should contain 5 meal IDs that work well together to meet the remaining nutrition targets.

      Consider:
      - Nutritional balance across the 5 meals in each set
      - Variety in meal types
      - Meeting (but not significantly exceeding) the remaining targets
      - Each of the 3 sets should be different from each other
    PROMPT
  end

  def fetch_candidate_meals(remaining_nutrients)
    max_calories_per_meal = remaining_nutrients[:calories] * 0.5
    min_calories_per_meal = remaining_nutrients[:calories] * 0.1

    Meal.where("calories BETWEEN ? AND ?", min_calories_per_meal, max_calories_per_meal)
        .order("RANDOM()")
        .limit(50)
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
    user_meals = @user.user_meals_on_date(@date).includes(:meal)

    {
      calories: user_meals.sum { |um| um.meal&.calories || 0 },
      proteins: user_meals.sum { |um| um.meal&.proteins || 0 },
      carbs: user_meals.sum { |um| um.meal&.carbs || 0 },
      fats: user_meals.sum { |um| um.meal&.fats || 0 }
    }
  end
end
