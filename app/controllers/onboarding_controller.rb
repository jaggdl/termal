class OnboardingController < ApplicationController
  allow_unauthenticated_access only: %i[ show create ]
  skip_before_action :authenticate_and_redirect

  def show
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
end
