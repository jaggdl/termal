class AddPeriodToNutritionAnalyses < ActiveRecord::Migration[8.0]
  def change
    add_column :nutrition_analyses, :period, :string
  end
end
