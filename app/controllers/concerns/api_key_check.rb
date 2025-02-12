module ApiKeyCheck
  extend ActiveSupport::Concern

  included do
    before_action :check_api_key, if: :api_key_check_required?
  end

  private

  def check_api_key
    unless GlobalSetting.get("openai_api_key").present?
      redirect_to global_settings_path, alert: "The OpenAI API key is not set. Please set it in the global settings."
    end
  end

  def api_key_check_required?
    if respond_to?(:api_key_check_actions, true)
      api_key_check_actions.include?(action_name.to_sym)
    else
      false
    end
  end
end
