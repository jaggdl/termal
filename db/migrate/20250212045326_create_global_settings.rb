class CreateGlobalSettings < ActiveRecord::Migration[7.0]
  def change
    create_table :global_settings do |t|
      t.string :name, null: false
      t.string :value

      t.timestamps
    end
    add_index :global_settings, :name, unique: true
  end
end
