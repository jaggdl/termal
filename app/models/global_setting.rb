class GlobalSetting < ApplicationRecord
  validates :name, uniqueness: true

  SETTING_KEYS = %w[
    openai_api_key
    anthropic_api_key
    gemini_api_key
    meal_analysis_model
    vapid_public_key
    vapid_private_key
    vapid_contact_email
  ]

  SETTING_KEYS.each do |key|
    define_method key do
      self.value
    end

    define_method "#{key}=" do |value|
      self.value = value
    end
  end

  def self.get(key)
    setting = find_or_create_by(name: key)
    setting.value
  end

  def self.set(key, value)
    setting = find_or_initialize_by(name: key)
    setting.value = value
    setting.save!
  end
end
