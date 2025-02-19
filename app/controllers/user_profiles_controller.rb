class UserProfilesController < ApplicationController
  before_action :set_user_profile, only: [:show, :update]

  def show
    @profile = Current.user_profile || UserProfile.new
    @profile.timezone ||= cookies[:timezone]
  end

  def update
    unless @profile
      create_user_profile
      redirect_to profile_path, notice: 'Profile was successfully updated.'
      return
    end

    if @profile.update(profile_params)
      redirect_to profile_path, notice: 'Profile was successfully updated.'
    else
      render :show, alert: 'Something went wrong'
    end
  end

  private

  def set_user_profile
    @profile = Current.user_profile
  end

  def create_user_profile
    profile = UserProfile.new(profile_params)
    profile.user = Current.user
    profile.save
  end

  def profile_params
    params.require(:user_profile).permit(:age, :sex, :weight, :height, :physical_activity, :weight_goals, :muscle_building, :timezone)
  end
end
