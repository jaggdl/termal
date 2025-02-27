class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern

  before_action :authenticate_and_redirect

  private

  def authenticate_and_redirect
    if !authenticated? && User.count.zero?
      redirect_to onboarding_path
    end
  end
end
