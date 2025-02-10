class CreateMeals < ActiveRecord::Migration[8.0]
  def change
    create_table :meals do |t|
      t.datetime :consumed_at, null: false
      t.string :meal_name, null: false
      t.integer :calories, null: false
      t.float :fats, null: false
      t.float :proteins, null: false

      t.timestamps
    end
  end
end
