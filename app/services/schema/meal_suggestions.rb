class Schema::MealSuggestions < RubyLLM::Schema
  array :meal_sets do
    object do
      array :meal_ids, of: :integer
    end
  end
end
