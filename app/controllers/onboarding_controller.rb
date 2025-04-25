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
      # Generate and store VAPID keys if they don't exist
      generate_vapid_keys if vapid_keys_missing?

      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to onboarding_path, alert: "Try another email address or password."
    end
  end

  private

  def redirect_if_users_exist
    # If users exist, redirect to root or login page
    # This ensures only the first user can register directly,
    # all other users need to use an invite link
    if User.exists?
      redirect_to new_session_path, alert: "Registration is by invitation only. Please contact an admin for an invite."
    end
  end

  def vapid_keys_missing?
    GlobalSetting.get("vapid_public_key").blank? || GlobalSetting.get("vapid_private_key").blank?
  end

  def generate_vapid_keys
    vapid_key = WebPush.generate_key

    GlobalSetting.set("vapid_public_key", vapid_key.public_key)
    GlobalSetting.set("vapid_private_key", vapid_key.private_key)
  end
end
