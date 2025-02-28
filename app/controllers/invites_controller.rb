class InvitesController < ApplicationController
  before_action :verify_can_invite, only: [ :index, :regenerate, :invalidate ]

  def index
    @invite = Invite.get_active_for(Current.user)
    @users = User.includes(:user_profile).order(created_at: :desc)
  end

  def regenerate
    @invite = Current.user.invites.active.first

    if @invite
      @invite.regenerate!
    else
      @invite = Current.user.invites.create
    end

    redirect_to family_path, notice: "Invite link regenerated successfully"
  end

  def invalidate
    @invite = Current.user.invites.active.first

    if @invite
      @invite.invalidate!
      redirect_to family_path, notice: "Invite link invalidated successfully"
    else
      redirect_to family_path, alert: "No active invite to invalidate"
    end
  end

  private

  def verify_can_invite
    unless Current.user.can_invite?
      redirect_to root_path, alert: "You do not have permission to manage family"
    end
  end
end
