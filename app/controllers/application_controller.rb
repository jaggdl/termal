class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :set_timezone

  def set_timezone
    @timezone = cookies[:timezone] || "UTC"
  end
end
