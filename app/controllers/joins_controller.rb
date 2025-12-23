class JoinsController < ApplicationController
  allow_unauthenticated_access
  skip_before_action :authenticate_and_redirect
  before_action :find_invite_by_token

  def new
    @token = @invite.token
  end

  def create
    unless user = User.new(params.permit(:email_address, :password))
      render :new, status: :unprocessable_entity, alert: "Try another email address or password."
      return
    end

    user.user_profile = UserProfile.new(
      timezone: cookies[:timezone]
    )

    if user.save
      start_new_session_for user
      redirect_to profile_path, notice: "Welcome! Please complete your profile to continue."
    else
      @token = @invite.token
      render :new, status: :unprocessable_entity, alert: "Unable to create account"
    end
  end

  private

  def find_invite_by_token
    @invite = Invite.find_by(token: params[:token])

    unless @invite
      redirect_to new_session_path, alert: "Invalid invite link"
    end
  end
end
