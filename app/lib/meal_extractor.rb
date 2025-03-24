class MealUpdateSuccess < StandardError; end

class MealExtractor < RubyLLM::Tool
  description "Extract nutritional information, meal name, and brief description from an image or text"

  param :meal_name,
    type: :string,
    desc: "The name or title of the meal"

  param :description,
    type: :string,
    desc: "A very concise description of the meal (max 15 words) mentioning only essential information about primary ingredients"

  param :calories,
    type: :integer,
    desc: "Total calories in the meal"

  param :fats,
    type: :number,
    desc: "Total grams of fat"

  param :proteins,
    type: :number,
    desc: "Total grams of protein"

  param :carbs,
    type: :number,
    desc: "Total grams of carbohydrates"

  param :fiber,
    type: :number,
    desc: "Total grams of dietary fiber"

  param :sodium,
    type: :number,
    desc: "Total milligrams of sodium"

  param :sugar,
    type: :number,
    desc: "Total grams of sugar"

  param :cholesterol,
    type: :number,
    desc: "Total milligrams of cholesterol"

  def initialize(meal)
    @meal = meal
  end

  def execute(meal_name:, description:, calories:, fats:, proteins:, carbs:, fiber:, sodium:, sugar:, cholesterol:)
    @meal.update({
      meal_name:,
      description:,
      calories:,
      fats:,
      proteins:,
      carbs:,
      fiber:,
      sodium:,
      sugar:,
      cholesterol:
    })

    # This is to avoid calling another chat completion
    raise MealUpdateSuccess, "Meal updated successfully"
  end
end
