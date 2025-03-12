class InvitesController < ApplicationController
  before_action :verify_is_admin, only: [ :index, :regenerate, :destroy_user ]

  def index
    @invite = Current.user.invites.first_or_create
    @users = User.includes(:user_profile).order(created_at: :desc)
  end

  def regenerate
    @invite = Current.user.invites.first_or_create
    @invite.regenerate!

    redirect_to family_path, notice: "Invite link regenerated successfully"
  end

  def destroy_user
    user = User.find(params[:id])

    # Prevent deletion of the admin/first user
    if user.is_admin?
      redirect_to family_path, alert: "Cannot delete the admin user"
      return
    end

    # Prevent self-deletion
    if user.id == Current.user.id
      redirect_to family_path, alert: "Cannot delete your own account"
      return
    end

    user.destroy

    redirect_to family_path, notice: "User has been deleted successfully"
  end

  private

  def verify_is_admin
    unless Current.user.is_admin?
      redirect_to root_path, alert: "You do not have permission to manage family"
    end
  end
end
