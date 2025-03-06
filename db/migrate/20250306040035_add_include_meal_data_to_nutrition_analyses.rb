class AddIncludeMealDataToNutritionAnalyses < ActiveRecord::Migration[8.0]
  def change
    add_column :nutrition_analyses, :include_meal_data, :boolean, default: false
  end
end
