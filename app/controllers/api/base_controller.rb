module Api
  class BaseController < ApplicationController
    include ApiAuthentication
    skip_before_action :verify_authenticity_token
    skip_around_action :set_current_timezone

    around_action :set_api_timezone

    private
      def set_api_timezone(&)
        Time.use_zone(Current.user.user_profile&.timezone, &)
      end
  end
end
