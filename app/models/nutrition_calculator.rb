class NutritionCalculator
  # Activity factors for TDEE calculation
  ACTIVITY_FACTORS = {
    "sedentary" => 1.2,
    "lightly_active" => 1.375,
    "moderately_active" => 1.55,
    "very_active" => 1.725,
    "extremely_active" => 1.9
  }.freeze

  # Protein multipliers based on muscle goals
  PROTEIN_MULTIPLIERS = {
    "build_muscle" => 2.0,
    "maintain_muscle" => 1.2
  }.freeze

  # Default values for average person
  DEFAULT_TARGETS = {
    calories: 2000,
    proteins: 50,
    carbs: 250,
    fats: 70,
    fiber: 25,
    sodium: 2300,
    sugar: 30,
    cholesterol: 300
  }.freeze

  # Default values to use in calculations if profile data is missing
  DEFAULT_VALUES = {
    sex: "male",
    weight: 70, # kg
    height: 170, # cm
    age: 30,
    physical_activity: "moderately_active",
    weight_goals: "maintain",
    muscle_building: "maintain_muscle"
  }.freeze

  def initialize(user_profile)
    @user_profile = user_profile
  end

  def daily_targets
    @daily_targets ||= calculate_daily_targets
  end

  private

  def calculate_daily_targets
    # Calculate BMR and TDEE
    bmr = calculate_bmr
    activity = @user_profile.physical_activity || DEFAULT_VALUES[:physical_activity]
    tdee = bmr * ACTIVITY_FACTORS[activity]

    # Adjust calories based on weight goals
    calories = adjust_calories(tdee)

    # Calculate macronutrients
    protein = calculate_protein
    protein_calories = protein * 4
    remaining_calories = calories - protein_calories

    # Split remaining calories evenly between carbs and fats
    carbs = (remaining_calories / 2) / 4  # 4 kcal/g for carbs
    fats = (remaining_calories / 2) / 9   # 9 kcal/g for fats

    # Calculate fiber based on carbs (general guideline: ~10% of carbs)
    fiber = carbs * 0.1

    # Calculate other nutrients based on general guidelines and calories
    # These are approximations based on standard recommendations
    sodium = 2300 # mg, standard recommendation
    sugar = calories * 0.015 # About 30g per 2000 calories
    cholesterol = 300 # mg, standard recommendation

    # Return rounded results
    {
      calories: calories.round,
      proteins: protein.round,
      carbs: carbs.round,
      fats: fats.round,
      fiber: fiber.round,
      sodium: sodium,
      sugar: sugar.round,
      cholesterol: cholesterol
    }
  rescue
    # Return default targets if calculation fails
    DEFAULT_TARGETS
  end

  def calculate_bmr
    sex = @user_profile.sex || DEFAULT_VALUES[:sex]
    weight = @user_profile.weight || DEFAULT_VALUES[:weight]
    height = @user_profile.height || DEFAULT_VALUES[:height]
    age = @user_profile.age || DEFAULT_VALUES[:age]

    if sex == "male"
      (10 * weight) + (6.25 * height) - (5 * age) + 5
    else
      (10 * weight) + (6.25 * height) - (5 * age) - 161
    end
  end

  def adjust_calories(tdee)
    weight_goals = @user_profile.weight_goals || DEFAULT_VALUES[:weight_goals]

    case weight_goals
    when "lose_weight"
      tdee - 500
    when "gain_weight"
      tdee + 500
    else # "maintain"
      tdee
    end
  end

  def calculate_protein
    muscle_building = @user_profile.muscle_building || DEFAULT_VALUES[:muscle_building]
    weight = @user_profile.weight || DEFAULT_VALUES[:weight]

    multiplier = PROTEIN_MULTIPLIERS[muscle_building]
    weight * multiplier
  end
end
