class CreateUserMeals < ActiveRecord::Migration[7.0]
  def change
    create_table :user_meals do |t|
      t.references :user, null: false, foreign_key: true
      t.references :meal, null: false, foreign_key: true
      t.datetime :consumed_at, null: false

      t.timestamps
    end
  end
end
