class AddNotNullToMealName < ActiveRecord::Migration[8.0]
  def change
    change_column_null :meals, :meal_name, true
    change_column_null :meals, :calories, true
    change_column_null :meals, :fats, true
    change_column_null :meals, :proteins, true
  end
end
