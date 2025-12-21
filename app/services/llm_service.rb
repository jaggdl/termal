class LlmService
  def initialize(model: nil)
    @model = model || LlmConfig.meal_analysis_model

    unless LlmConfig.api_key_for(@model)
      provider = LlmConfig.provider_for(@model)
      raise StandardError, "#{provider&.titleize || 'Provider'} API key is not set. Please set it in the global settings."
    end

    RubyLLM.configure do |config|
      config.max_retries = 0
      config.openai_api_key = LlmConfig.openai_api_key
      config.anthropic_api_key = LlmConfig.anthropic_api_key
      config.gemini_api_key = LlmConfig.gemini_api_key
    end
  end

  def embedding(input)
    response = RubyLLM.embed(input)

    response.vectors
  end

  def analyze_meal(meal)
    instruction_text = "Analyze this meal image and provide brief information including nutritional content, meal name, and a very concise description of the meal (max 15 words). Only include the most essential information about the primary ingredients."

    chat.with_schema(Schema::Meal)
    chat.add_message role: :user, content: instruction_text

    user_message = meal.prompt || "Analyze this meal:"

    response = chat.ask(user_message, with: { image: meal.image_paths })

    response.content
  end

  def analyze_nutrition(user_profile:, summary_data:, meal_data:)
    prompt_template = ApplicationController.renderer.render(
      partial: "templates/nutrition_analysis_prompt",
      locals: { user_profile:, summary_data:, meal_data: }
    )

    response = chat.ask prompt_template

    response.content
  end

  private

  def chat
    @chat ||= RubyLLM.chat(model: @model)
  end
end
