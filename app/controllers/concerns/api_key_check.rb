module ApiKeyCheck
  extend ActiveSupport::Concern

  included do
    helper_method :check_api_key
  end

  private

  def check_api_key
    unless GlobalSetting.get("openai_api_key").present?
      session[:return_to_after_setting_api_key] = request.url
      redirect_to global_settings_path, alert: "The OpenAI API key is not set. Please set it in the global settings."
    end
  end

  def after_setting_api_key_url
    session.delete(:return_to_after_setting_api_key)
  end
end
