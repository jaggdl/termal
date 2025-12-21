class LlmConfig
  MODELS = {
    "openai" => %w[o4-mini],
    "gemini" => %w[gemini-2.5-pro]
  }.freeze

  DEFAULT_MODEL = "o4-mini"

  class << self
    def available_models
      MODELS.values.flatten
    end

    def models_for_select
      MODELS.flat_map do |provider, models|
        models.map { |model| [ model, model ] }
      end
    end

    def provider_for(model)
      MODELS.find { |_provider, models| models.include?(model) }&.first
    end

    def meal_analysis_model
      GlobalSetting.get(:meal_analysis_model).presence || DEFAULT_MODEL
    end

    def openai_api_key
      GlobalSetting.get(:openai_api_key)
    end

    def anthropic_api_key
      GlobalSetting.get(:anthropic_api_key)
    end

    def gemini_api_key
      GlobalSetting.get(:gemini_api_key)
    end

    def api_key_for(model)
      provider = provider_for(model)
      return nil unless provider

      send("#{provider}_api_key")
    end

    def api_key_set_for?(model)
      api_key_for(model).present?
    end

    def current_meal_analysis_api_key
      api_key_for(meal_analysis_model)
    end

    def current_meal_analysis_api_key_set?
      current_meal_analysis_api_key.present?
    end
  end
end
