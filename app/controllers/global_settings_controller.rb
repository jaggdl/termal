class GlobalSettingsController < ApplicationController
  include ApiKeyCheck

  before_action :check_if_user_is_owner

  def index
    @settings = GlobalSetting.all
  end

  def update
    settings_params.each do |key, value|
      GlobalSetting.set(key, value)
    end

    if !LlmConfig.current_meal_analysis_api_key_set?
      provider = LlmConfig.provider_for(LlmConfig.meal_analysis_model)&.titleize
      redirect_to global_settings_path, alert: "#{provider} API key is required for the selected model."
      return
    end

    redirect_to after_setting_api_key_url || global_settings_path, notice: "Settings were successfully updated."
  rescue => e
    redirect_to global_settings_path, alert: "An error occurred: #{e.message}"
  end

  private

  def settings_params
    params.fetch("global_settings", {}).permit(GlobalSetting::SETTING_KEYS)
  end

  def check_if_user_is_owner
    unless Current.user.email_address == User.first.email_address
      redirect_to root_path, alert: "You are not allowed here"
    end
  end
end
