class NutritionCalculator
  include FitnessOptions

  # Default values for average person (adjusted to more realistic averages)
  # Calories: 2000-2500 typical; macros based on standard recommendations.
  DEFAULT_TARGETS = {
    calories: 2000,
    proteins: 56,  # RDA 0.8g/kg for 70kg
    carbs: 275,
    fats: 67
  }.freeze

  # Default values to use in calculations if profile data is missing
  # Weight/height/age averages from general population data.
  DEFAULT_VALUES = {
    sex: "male",
    weight: 75, # kg, approximate global average
    height: 170, # cm
    age: 30,
    physical_activity: :moderately_active,
    weight_goals: "maintain",
    muscle_building: :maintain_muscle
  }.freeze

  def initialize(user_profile)
    @user_profile = user_profile
  end

  def daily_targets
    @daily_targets ||= calculate_daily_targets
  end

  private

  def calculate_daily_targets
    # Calculate BMR using Mifflin-St Jeor equation, considered most accurate
    # Source: https://www.jandonline.org/article/S0002-8223(05)00149-5/abstract
    bmr = calculate_bmr

    # Calculate TDEE
    activity = (@user_profile.physical_activity&.to_sym || DEFAULT_VALUES[:physical_activity])
    tdee = bmr * ACTIVITY_FACTORS[activity]

    # Adjust calories based on weight goals (±500 kcal for ~0.5kg/week safe rate)
    calories = adjust_calories(tdee)

    # Calculate macronutrients
    protein = calculate_protein
    protein_calories = protein * 4

    # Set fats to ~30% of total calories (within AMDR 20-35%)
    fat_calories = [ calories * 0.3, calories * 0.2 ].max.round
    fats = (fat_calories / 9).round

    # Remaining for carbs
    carb_calories = calories - protein_calories - fat_calories
    carbs = (carb_calories / 4).round

    # If carbs negative (rare, high protein low cal), adjust fats down
    if carb_calories < 0
      fat_calories += carb_calories
      fats = (fat_calories / 9).round
      carbs = 0
    end

    # Return rounded results
    {
      calories: calories.round,
      proteins: protein.round,
      carbs: carbs.round,
      fats: fats.round
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
    sex = @user_profile.sex || DEFAULT_VALUES[:sex]
    min_calories = sex == "male" ? 1500 : 1200  # Safer minimums by sex

    case weight_goals
    when "lose_weight"
      [ tdee - 500, min_calories ].max  # Ensure not below safe minimum
    when "gain_weight"
      tdee + 500
    else # "maintain"
      tdee
    end
  end

  def calculate_protein
    muscle_building = (@user_profile.muscle_building&.to_sym || DEFAULT_VALUES[:muscle_building])
    weight = @user_profile.weight || DEFAULT_VALUES[:weight]
    age = @user_profile.age || DEFAULT_VALUES[:age]

    multiplier = PROTEIN_MULTIPLIERS[muscle_building]
    if muscle_building == :maintain_muscle && age >= 50
      multiplier = 1.2
    end
    weight * multiplier
  end
end
