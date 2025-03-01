class AddErrorToUserMeals < ActiveRecord::Migration[8.0]
  def change
    add_column :user_meals, :error, :string
  end
end
