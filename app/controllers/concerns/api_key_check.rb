module ApiKeyCheck
  extend ActiveSupport::Concern

  included do
    helper_method :check_api_key
  end

  private

  def check_api_key
    unless LlmConfig.current_meal_analysis_api_key_set?
      session[:return_to_after_setting_api_key] = request.url
      model = LlmConfig.meal_analysis_model
      provider = LlmConfig.provider_for(model)&.titleize || "Provider"
      redirect_to global_settings_path, alert: "The #{provider} API key is not set. Please set it in the global settings."
    end
  end

  def after_setting_api_key_url
    session.delete(:return_to_after_setting_api_key)
  end
end
