module CurrentTimezone
  extend ActiveSupport::Concern

  included do
    around_action :set_current_timezone
    etag { timezone_from_cookie }
  end

  private
    def set_current_timezone(&)
      Time.use_zone(timezone, &)
    end

    def timezone
      Current.user_profile&.timezone || timezone_from_cookie
    end

    def timezone_from_cookie
      cookies[:timezone].presence
    end
end
