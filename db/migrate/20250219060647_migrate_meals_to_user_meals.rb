class MigrateMealsToUserMeals < ActiveRecord::Migration[8.0]
  def up
    Meal.find_each do |meal|
      UserMeal.create!(
        user_id: meal.user_id,
        meal_id: meal.id,
        consumed_at: meal.read_attribute(:consumed_at)
      )
    end
  end

  def down
    UserMeal.delete_all
  end
end
