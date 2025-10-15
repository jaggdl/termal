class AddLocationToUserMeals < ActiveRecord::Migration[8.0]
  def change
    add_column :user_meals, :latitude, :decimal, precision: 10, scale: 6
    add_column :user_meals, :longitude, :decimal, precision: 10, scale: 6
  end
end
