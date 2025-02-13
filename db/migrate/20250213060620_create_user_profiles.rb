class CreateUserProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :user_profiles do |t|
      t.integer :age
      t.string :sex
      t.float :weight
      t.float :height
      t.string :physical_activity
      t.string :weight_goals
      t.string :muscle_building
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
