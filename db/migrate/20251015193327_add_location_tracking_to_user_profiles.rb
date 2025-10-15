class AddLocationTrackingToUserProfiles < ActiveRecord::Migration[8.0]
  def change
    add_column :user_profiles, :enable_location_tracking, :boolean, default: false
  end
end
