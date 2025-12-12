class Schema::Meal < RubyLLM::Schema
  string :meal_name, description: "The name or title of the meal"
  string :description, description: "A very concise description of the meal (max 15 words) mentioning only essential information about primary ingredients"
  integer :calories, description: "Total calories in the meal"
  number :fats, description: "Total grams of fat"
  number :proteins, description: "Total grams of protein"
  number :carbs, description: "Total grams of carbohydrates"
end
