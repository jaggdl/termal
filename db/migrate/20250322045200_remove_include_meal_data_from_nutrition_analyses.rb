class RemoveIncludeMealDataFromNutritionAnalyses < ActiveRecord::Migration[8.0]
  def change
    remove_column :nutrition_analyses, :include_meal_data, :boolean
  end
end
