class NutritionCalculator
  # Activity factors for TDEE calculation based on Physical Activity Level (PAL) values
  # Source: https://pmc.ncbi.nlm.nih.gov/articles/PMC3636460/ - Physical activity and physical activity induced energy expenditure in humans: measurement, determinants, and effects
  # Average PAL ranges from 1.4 to 1.9 depending on age and activity; these multipliers are standard estimates.
  ACTIVITY_FACTORS = {
    "sedentary" => 1.2,
    "lightly_active" => 1.375,
    "moderately_active" => 1.55,
    "very_active" => 1.725,
    "extremely_active" => 1.9
  }.freeze

  # Protein multipliers based on muscle goals (g/kg body weight)
  # Source: https://examine.com/guides/protein-intake/ - Optimal Protein Intake Guide & Calculator
  # Maintenance: 1.2–1.8 g/kg; Muscle gain: 1.6–2.7 g/kg. Adjusted to 1.6 for maintain, 2.2 for build based on meta-analyses.
  # Additional source: https://pubmed.ncbi.nlm.nih.gov/35187864/ - Systematic review and meta-analysis of protein intake to support muscle mass and function in healthy adults
  # For older adults (age >=50), maintenance adjusted to 1.2 g/kg
  # Source: https://acl.gov/sites/default/files/nutrition/Nutrition-Needs_Protein_FINAL-2.18.20_508.pdf - Nutrition Needs for Older Adults: Protein (recommends 1-1.2 g/kg)
  # Additional source: https://pmc.ncbi.nlm.nih.gov/articles/PMC11150820/ - Discussion on protein recommendations for supporting muscle and bone health in older adults
  PROTEIN_MULTIPLIERS = {
    "build_muscle" => 2.2,
    "maintain_muscle" => 1.6
  }.freeze

  # Default values for average person (adjusted to more realistic averages)
  # Calories: 2000-2500 typical; macros based on standard recommendations.
  DEFAULT_TARGETS = {
    calories: 2000,
    proteins: 56,  # RDA 0.8g/kg for 70kg
    carbs: 275,
    fats: 67,
    fiber: 28,
    sodium: 2300,
    sugar: 25,
    cholesterol: 300
  }.freeze

  # Default values to use in calculations if profile data is missing
  # Weight/height/age averages from general population data.
  DEFAULT_VALUES = {
    sex: "male",
    weight: 75, # kg, approximate global average
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
    # Calculate BMR using Mifflin-St Jeor equation, considered most accurate
    # Source: https://www.jandonline.org/article/S0002-8223(05)00149-5/abstract - Comparison of Predictive Equations for Resting Metabolic Rate in Healthy Nonobese and Obese Adults: A Systematic Review
    # Mifflin-St Jeor predicted within 10% in more individuals than other equations.
    # Additional source: https://nutrium.com/blog/mifflin-st-jeor-for-nutrition-professionals/ - Mifflin-St. Jeor for nutrition professionals
    bmr = calculate_bmr

    # Calculate TDEE
    activity = @user_profile.physical_activity || DEFAULT_VALUES[:physical_activity]
    tdee = bmr * ACTIVITY_FACTORS[activity]

    # Adjust calories based on weight goals (±500 kcal for ~0.5kg/week safe rate)
    # Source: https://www.healthline.com/nutrition/calorie-deficit - What Is a Calorie Deficit, and How Much of One Is Healthy?
    # 300–500 calories deficit effective for sustainable weight loss.
    # Additional source: https://www.mayoclinic.org/healthy-lifestyle/weight-loss/in-depth/calories/art-20048065 - Counting calories: Get back to weight-loss basics
    # For sustainability, keeping fixed 500 kcal deficit as per multiple sources recommending 500-750 kcal
    # Source: https://www.webmd.com/diet/calorie-deficit - Calorie Deficit: A Complete Guide (500 kcal/day for 1lb/week)
    calories = adjust_calories(tdee)

    # Calculate macronutrients
    # Protein first, based on body weight and goals
    protein = calculate_protein
    protein_calories = protein * 4

    # Set fats to ~30% of total calories (within AMDR 20-35%)
    # Source: https://www.sciencedirect.com/science/article/pii/S2161831322007165 - Optimizing Protein Intake in Adults: Interpretation and Application of the Recommended Dietary Allowance Compared with the Acceptable Macronutrient Distribution Range
    # AMDR: 20–35% fats, 45–65% carbs, 10–35% protein.
    # Additional source: https://www.nsca.com/education/articles/nsca-coach/how-low-can-you-goconsiderations-for-low-carbohydrate-diets/ - How Low Can You Go—Considerations for Low-Carbohydrate Diets
    # Ensure minimum 20% for essential fats
    # Source: https://knowledge4policy.ec.europa.eu/health-promotion-knowledge-gateway/dietary-fats-table-4_en - Dietary recommendations for fat intake (min 15-20 E%)
    # Additional source: https://www.healthline.com/nutrition/how-much-fat-to-eat - Fat Grams: How Much Fat Should You Eat Per Day? (20-35%)
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

    # Calculate fiber based on sex and age (fixed recommendations)
    # Source: https://www.dietaryguidelines.gov/sites/default/files/2020-12/Dietary_Guidelines_for_Americans_2020-2025.pdf - Dietary Guidelines for Americans, 2020-2025
    # Men <=50: 38g, >50: 30g; Women <=50: 25g, >50: 21g
    # Additional source: https://health.clevelandclinic.org/how-much-fiber-per-day - How Much Fiber Do You Need per Day?
    fiber = calculate_fiber

    # Sodium: 2300 mg limit
    # Source: https://www.heart.org/en/healthy-living/healthy-eating/eat-smart/sodium/sodium-and-salt - Get the Scoop on Sodium and Salt
    # AHA recommends <2300 mg, ideally 1500 mg.
    sodium = 2300 # mg

    # Sugar: Limit to <5% of calories as ideal recommendation
    # Source: https://www.who.int/publications/i/item/9789241549028 - Guideline: sugars intake for adults and children (WHO <10%, ideally <5%)
    # Additional source: https://www.who.int/tools/elena/interventions/free-sugars-adults-ncds - Reducing free sugars intake in adults to reduce the risk of NCDs
    sugar_calories = (calories * 0.05).round
    sugar = (sugar_calories / 4).round

    # Cholesterol: <300 mg, though recent guidelines emphasize patterns over limit
    # Source: https://www.ahajournals.org/doi/10.1161/CIR.0000000000000743 - Dietary Cholesterol and Cardiovascular Risk: A Science Advisory From the American Heart Association
    # Previous limit 300 mg/day, now focus on minimizing.
    cholesterol = 300 # mg

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
    muscle_building = @user_profile.muscle_building || DEFAULT_VALUES[:muscle_building]
    weight = @user_profile.weight || DEFAULT_VALUES[:weight]
    age = @user_profile.age || DEFAULT_VALUES[:age]

    multiplier = PROTEIN_MULTIPLIERS[muscle_building]
    if muscle_building == "maintain_muscle" && age >= 50
      multiplier = 1.2
    end
    weight * multiplier
  end

  def calculate_fiber
    sex = @user_profile.sex || DEFAULT_VALUES[:sex]
    age = @user_profile.age || DEFAULT_VALUES[:age]

    if sex == "male"
      age <= 50 ? 38 : 30
    else
      age <= 50 ? 25 : 21
    end
  end
end
