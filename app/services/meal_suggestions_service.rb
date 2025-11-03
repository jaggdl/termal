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

    meal_sets = llm_response["meal_sets"].map do |meal_set|
      meal_ids = meal_set["meal_ids"]
      meals = Meal.where(id: meal_ids).index_by(&:id)

      {
        meals: meal_ids.map { |id| meals[id] }.compact,
        description: meal_set["description"]
      }
    end

    { meal_sets: meal_sets }
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

      Generate 3 DIFFERENT meal sets, each containing meal IDs that work well together to meet the remaining nutrition targets.
      Each set should offer a different approach or combination.

      For each meal set, provide:
      1. An array of meal_ids
      2. A brief description (e.g., "High protein focus", "Balanced variety", "Light options")

      Consider:
      - Nutritional balance across the meals in each set
      - Variety in meal types and calorie levels within each set
      - Meeting (but not significantly exceeding) the remaining targets
      - Mix meals from different calorie groups for better variety
      - Make each of the 3 sets meaningfully different from each other
      - Vary the number of meals in each set (some sets can have 1-2 meals, others 3-4 meals)
    PROMPT
  end

  def format_meals_data(meals)
    return "None available" if meals.empty?

    meals.map do |meal|
      "ID: #{meal.id}, Name: #{meal.meal_name}, Calories: #{meal.calories}, Proteins: #{meal.proteins}g, Carbs: #{meal.carbs}g, Fats: #{meal.fats}g"
    end.join("\n")
  end

  def fetch_candidate_meals(remaining_nutrients)
    recently_eaten_ids = recently_eaten_meal_ids
    time_period = current_time_period
    time_preferred_meal_ids = time_preferred_meal_ids(time_period)

    base_query = Meal.joins(:user_meals)
                     .where(user_meals: { user_id: @user.id })

    base_query = base_query.where.not(id: recently_eaten_ids) if recently_eaten_ids.any?

    if time_preferred_meal_ids.any?
      time_preferred_ids_str = time_preferred_meal_ids.join(",")
      base_query = base_query.group("meals.id")
                             .select("meals.*, COUNT(user_meals.id) as usage_count,
                                     SUM(CASE WHEN user_meals.meal_id IN (#{time_preferred_ids_str}) THEN 2 ELSE 1 END) as time_score")
                             .order("time_score DESC, usage_count DESC")
    else
      base_query = base_query.group("meals.id")
                             .select("meals.*, COUNT(user_meals.id) as usage_count, 1 as time_score")
                             .order("usage_count DESC")
    end

    remaining_cals = remaining_nutrients[:calories]

    {
      low: base_query.where("meals.calories BETWEEN ? AND ?", remaining_cals * 0.1, remaining_cals * 0.4).limit(20),
      medium: base_query.where("meals.calories BETWEEN ? AND ?", remaining_cals * 0.3, remaining_cals * 0.7).limit(20),
      high: base_query.where("meals.calories BETWEEN ? AND ?", remaining_cals * 0.6, remaining_cals * 1.1).limit(20)
    }
  end

  def recently_eaten_meal_ids
    days_to_exclude = 3
    cutoff_date = @date - days_to_exclude.days

    UserMeal.where(user_id: @user.id)
            .where("DATE(consumed_at) > ? AND DATE(consumed_at) <= ?", cutoff_date, @date)
            .pluck(:meal_id)
            .uniq
  end

  def current_time_period
    current_hour = Time.current.in_time_zone(@user_profile.timezone).hour

    case current_hour
    when 6..10 then :morning
    when 11..15 then :afternoon
    when 16..21 then :evening
    else :late_night
    end
  end

  def time_preferred_meal_ids(time_period)
    hour_ranges = {
      morning: (6..10),
      afternoon: (11..15),
      evening: (16..21),
      late_night: [ (22..23).to_a, (0..5).to_a ].flatten
    }

    hours = hour_ranges[time_period]

    user_meals = UserMeal.where(user_id: @user.id).includes(:meal)

    meal_counts = Hash.new(0)
    user_meals.each do |user_meal|
      hour_in_timezone = user_meal.consumed_at.in_time_zone(@user_profile.timezone).hour
      meal_counts[user_meal.meal_id] += 1 if hours.include?(hour_in_timezone)
    end

    meal_counts.select { |_meal_id, count| count >= 2 }.keys
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
