class OnboardingController < ApplicationController
  allow_unauthenticated_access only: %i[ show create ]
  skip_before_action :authenticate_and_redirect
  before_action :redirect_if_users_exist, only: [ :show, :create ]

  def show
    # Renders the onboarding page if no users exist
  end

  def create
    unless user = User.new(params.permit(:email_address, :password))
      redirect_to onboarding_path, alert: "Try another email address or password."
      return
    end

    user.user_profile = UserProfile.new(
      timezone: cookies[:timezone]
    )

    if user.save
      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to onboarding_path, alert: "Try another email address or password."
    end
  end

  private

  def redirect_if_users_exist
    redirect_to root_path if User.exists?
  end
end
