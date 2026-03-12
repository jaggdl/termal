# frozen_string_literal: true

module Api
  class UserProfilesController < BaseController
    def show
      user_profile = Current.user.user_profile
      render json: UserProfileSerializer.new(user_profile)
    end
  end
end
