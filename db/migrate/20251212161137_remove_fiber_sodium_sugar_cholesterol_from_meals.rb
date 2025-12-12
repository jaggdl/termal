class RemoveFiberSodiumSugarCholesterolFromMeals < ActiveRecord::Migration[8.0]
  def change
    remove_column :meals, :fiber, :decimal
    remove_column :meals, :sodium, :decimal
    remove_column :meals, :sugar, :decimal
    remove_column :meals, :cholesterol, :decimal
  end
end
