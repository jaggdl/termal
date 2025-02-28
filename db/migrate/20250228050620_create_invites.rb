class CreateInvites < ActiveRecord::Migration[8.0]
  def change
    create_table :invites do |t|
      t.string :token
      t.references :user, null: false, foreign_key: true
      t.boolean :used, default: false

      t.timestamps
    end
    add_index :invites, :token, unique: true
  end
end
