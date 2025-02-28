class InvitesController < ApplicationController
  allow_unauthenticated_access only: [ :accept, :register ]
  before_action :verify_can_invite, only: [ :index, :regenerate, :invalidate ]
  before_action :find_invite_by_token, only: [ :accept ]

  def index
    @invite = Invite.get_active_for(Current.user)
  end

  def regenerate
    @invite = Current.user.invites.active.first

    if @invite
      @invite.regenerate!
    else
      @invite = Current.user.invites.create
    end

    redirect_to invites_path, notice: "Invite link regenerated successfully"
  end

  def invalidate
    @invite = Current.user.invites.active.first

    if @invite
      @invite.invalidate!
      redirect_to invites_path, notice: "Invite link invalidated successfully"
    else
      redirect_to invites_path, alert: "No active invite to invalidate"
    end
  end

  def accept
    # Show the signup form
    @token = @invite.token
  end

  def register
    @invite = Invite.find_by(token: params[:token])

    unless @invite
      redirect_to root_path, alert: "Invalid invite"
      return
    end

    unless user = User.new(params.permit(:email_address, :password))
      render :accept, status: :unprocessable_entity, alert: "Try another email address or password."
      return
    end

    user.user_profile = UserProfile.new(
      timezone: cookies[:timezone] || "UTC"
    )

    if user.save
      start_new_session_for user
      redirect_to root_path, notice: "Account created successfully"
    else
      @token = @invite.token
      render :accept, status: :unprocessable_entity, alert: "Unable to create account"
    end
  end

  private

  def verify_can_invite
    unless Current.user.can_invite?
      redirect_to root_path, alert: "You do not have permission to send invites"
    end
  end

  def find_invite_by_token
    @invite = Invite.find_by(token: params[:token])

    unless @invite
      redirect_to new_session_path, alert: "Invalid invite link"
    end
  end
end
