class CreateApiKeys < ActiveRecord::Migration[8.1]
  def change
    create_table :api_keys do |t|
      t.references :user, null: false, foreign_key: true
      t.string :key
      t.string :name
      t.datetime :last_used_at

      t.timestamps
    end
  end
end
