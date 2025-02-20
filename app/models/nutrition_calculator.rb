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
    tdee = bmr * ACTIVITY_FACTORS[@user_profile.physical_activity]

    # Adjust calories based on weight goals
    calories = adjust_calories(tdee)

    # Calculate macronutrients
    protein = calculate_protein
    protein_calories = protein * 4
    remaining_calories = calories - protein_calories

    # Split remaining calories evenly between carbs and fats
    carbs = (remaining_calories / 2) / 4  # 4 kcal/g for carbs
    fats = (remaining_calories / 2) / 9   # 9 kcal/g for fats

    # Return rounded results
    {
      calories: calories.round,
      protein: protein.round,
      carbs: carbs.round,
      fats: fats.round
    }
  end

  def calculate_bmr
    if @user_profile.sex == "male"
      (10 * @user_profile.weight) + (6.25 * @user_profile.height) - (5 * @user_profile.age) + 5
    else
      (10 * @user_profile.weight) + (6.25 * @user_profile.height) - (5 * @user_profile.age) - 161
    end
  end

  def adjust_calories(tdee)
    case @user_profile.weight_goals
    when "lose_weight"
      tdee - 500
    when "gain_weight"
      tdee + 500
    else # "maintain"
      tdee
    end
  end

  def calculate_protein
    multiplier = PROTEIN_MULTIPLIERS[@user_profile.muscle_building]
    @user_profile.weight * multiplier
  end
end
