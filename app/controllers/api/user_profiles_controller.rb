# frozen_string_literal: true

module Api
  class UserProfilesController < BaseController
    def show
      user_profile = Current.user.user_profile
      render json: UserProfileSerializer.new(user_profile)
    end

    def update
      user_profile = Current.user.user_profile

      if user_profile
        if user_profile.update(profile_params)
          render json: UserProfileSerializer.new(user_profile)
        else
          render json: { errors: user_profile.errors.full_messages }, status: :unprocessable_entity
        end
      else
        user_profile = Current.user.build_user_profile(profile_params)
        if user_profile.save
          render json: UserProfileSerializer.new(user_profile), status: :created
        else
          render json: { errors: user_profile.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end

    private

    def profile_params
      params.permit(:age, :sex, :weight, :height, :physical_activity, :weight_goals, :muscle_building, :timezone, :enable_location_tracking)
    end
  end
end
