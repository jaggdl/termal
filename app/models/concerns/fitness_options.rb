module FitnessOptions
  extend ActiveSupport::Concern

  PHYSICAL_ACTIVITIES = {
    sedentary: "Sedentary",
    lightly_active: "Lightly Active",
    moderately_active: "Moderately Active",
    very_active: "Very Active",
    extremely_active: "Extremely Active"
  }.freeze

  MUSCLE_GOALS = {
    build_muscle: "Build Muscle",
    maintain_muscle: "Maintain Muscle"
  }.freeze

  # Activity factors for TDEE calculation based on Physical Activity Level (PAL) values
  # Source: https://pmc.ncbi.nlm.nih.gov/articles/PMC3636460/
  ACTIVITY_FACTORS = {
    sedentary: 1.2,
    lightly_active: 1.375,
    moderately_active: 1.55,
    very_active: 1.725,
    extremely_active: 1.9
  }.freeze

  # Protein multipliers based on muscle goals (g/kg body weight)
  # Source: https://examine.com/guides/protein-intake/
  PROTEIN_MULTIPLIERS = {
    build_muscle: 2.2,
    maintain_muscle: 1.6
  }.freeze

  class_methods do
    def physical_activity_options
      PHYSICAL_ACTIVITIES
    end

    def muscle_goal_options
      MUSCLE_GOALS
    end

    def activity_factors
      ACTIVITY_FACTORS
    end

    def protein_multipliers
      PROTEIN_MULTIPLIERS
    end
  end
end
