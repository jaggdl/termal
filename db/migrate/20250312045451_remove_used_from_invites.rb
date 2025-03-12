class RemoveUsedFromInvites < ActiveRecord::Migration[8.0]
  def change
    remove_column :invites, :used, :boolean
  end
end
