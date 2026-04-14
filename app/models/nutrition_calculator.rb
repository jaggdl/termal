class NutritionCalculator
  include FitnessOptions

  # Default values for an average person
  DEFAULT_TARGETS = { calories: 2000, proteins: 56, carbs: 275, fats: 67 }.freeze
  DEFAULT_VALUES = {
    sex: "male", weight: 75, height: 170, age: 30,
    physical_activity: :moderately_active, weight_goals: "maintain",
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
    bmr = calculate_bmr
    activity = (@user_profile.physical_activity&.to_sym || DEFAULT_VALUES[:physical_activity])
    tdee = bmr * ACTIVITY_FACTORS[activity]

    # 1. Calorie Adjustment
    # Sets the target based on the user's specific goal (loss, gain, or maintenance)
    calories = adjust_calories(tdee)

    # 2. Protein Calculation (Priority 1)
    # High protein is essential for body recomposition to protect lean mass
    protein = calculate_protein
    protein_calories = protein * 4

    # 3. Fat Calculation (Priority 2 - Hormonal Health)
    # Instead of a fixed percentage, we use a weight-based floor (0.9g per kg)
    # to ensure hormonal stability, which is critical for female health.
    weight = @user_profile.weight || DEFAULT_VALUES[:weight]
    fats = (weight * 0.9).round
    fat_calories = fats * 9

    # 4. Carbohydrate Calculation (The remainder)
    # Carbs fill the remaining calorie budget to fuel training sessions
    carb_calories = calories - protein_calories - fat_calories
    carbs = (carb_calories / 4).round

    # Safeguard: If carbs drop too low, we adjust fats to the absolute minimum floor
    if carbs < 100
      fats = (weight * 0.7).round # Absolute minimum: 0.7g/kg
      fat_calories = fats * 9
      carb_calories = calories - protein_calories - fat_calories
      carbs = (carb_calories / 4).round
    end

    {
      calories: calories.round,
      proteins: protein.round,
      carbs: carbs.round,
      fats: fats.round
    }
  rescue
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
    muscle_building = (@user_profile.muscle_building&.to_sym || DEFAULT_VALUES[:muscle_building])

    case weight_goals
    when "lose_weight"
      # For body recomposition (losing fat + gaining muscle),
      # a conservative deficit (12%) is more effective than an aggressive one.
      is_recomp = muscle_building != :maintain_muscle
      deficit = is_recomp ? (tdee * 0.12) : (tdee * 0.20)
      tdee - deficit
    when "gain_weight"
      # A controlled 300kcal surplus minimizes excessive fat gain during a bulk
      tdee + 300
    else
      tdee
    end
  end

  def calculate_protein
    muscle_building = (@user_profile.muscle_building&.to_sym || DEFAULT_VALUES[:muscle_building])
    weight = @user_profile.weight || DEFAULT_VALUES[:weight]

    # If the user aims to build muscle (recomp), we use 2.2g per kg
    multiplier = (muscle_building != :maintain_muscle) ? 2.2 : 1.6
    weight * multiplier
  end
end
