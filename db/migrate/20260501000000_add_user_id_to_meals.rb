class AddUserIdToMeals < ActiveRecord::Migration[8.1]
  def up
    add_column :meals, :user_id, :integer

    execute <<-SQL
      UPDATE meals
      SET user_id = COALESCE(
        (SELECT user_meals.user_id
         FROM user_meals
         WHERE user_meals.meal_id = meals.id
         LIMIT 1),
        1
      )
    SQL

    change_column_null :meals, :user_id, false

    add_index :meals, :user_id
    add_foreign_key :meals, :users
  end

  def down
    remove_foreign_key :meals, :users
    remove_index :meals, :user_id
    remove_column :meals, :user_id
  end
end
