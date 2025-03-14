class RemovePeriodFromNutritionAnalyses < ActiveRecord::Migration[8.0]
  def change
    remove_column :nutrition_analyses, :period, :string
  end
end
