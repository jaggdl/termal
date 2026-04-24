class ApplicationController < ActionController::Base
  include Authentication
  include CurrentTimezone
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern

  before_action :set_current_location
  before_action :authenticate_and_redirect
  before_action :require_profile_completion

  private

  def set_current_location
    Current.latitude = cookies[:user_latitude]
    Current.longitude = cookies[:user_longitude]
  end

  def authenticate_and_redirect
    if !authenticated? && User.count.zero?
      redirect_to onboarding_path
    end
  end

  def require_profile_completion
    return unless authenticated?
    return if profile_completed?

    redirect_to profile_path, alert: "Please complete your profile to continue."
  end

  def profile_completed?
    Current.user_profile&.profile_completed?
  end
end
