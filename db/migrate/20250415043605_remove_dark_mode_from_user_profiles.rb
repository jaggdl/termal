class RemoveDarkModeFromUserProfiles < ActiveRecord::Migration[8.0]
  def change
    remove_column :user_profiles, :dark_mode, :boolean
  end
end
