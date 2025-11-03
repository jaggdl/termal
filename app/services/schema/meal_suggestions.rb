class Schema::MealSuggestions < RubyLLM::Schema
  object :meal_set do
    array :meal_ids, of: :integer
  end
end
