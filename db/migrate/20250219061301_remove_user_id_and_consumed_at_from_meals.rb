class RemoveUserIdAndConsumedAtFromMeals < ActiveRecord::Migration[8.0]
  def change
    remove_column :meals, :user_id, :integer
    remove_column :meals, :consumed_at, :datetime
  end
end
