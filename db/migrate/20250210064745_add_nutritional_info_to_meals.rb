class AddNutritionalInfoToMeals < ActiveRecord::Migration[8.0]
  def change
    add_column :meals, :carbs, :float
    add_column :meals, :fiber, :float
    add_column :meals, :sodium, :integer
    add_column :meals, :sugar, :float
    add_column :meals, :cholesterol, :integer
  end
end
