require "ruby_llm"
require_relative "../lib/tools/meal_extractor"

class LlmService
  def initialize
    @openai_api_key = GlobalSetting.get("openai_api_key")

    unless @openai_api_key
      raise StandardError, "OpenAI API key is not set. Please set it in the global settings."
    end

    # Configure RubyLLM with the API key
    RubyLLM.configure do |config|
      config.openai_api_key = @openai_api_key
    end
  end

  def embedding(input)
    response = RubyLLM.embed(input)

    response.vectors
  end

  def analyze_meal_image(meal)
    instruction_text = "Analyze this meal image and provide brief information including nutritional content, meal name, and a very concise description of the meal (max 15 words). Only include the most essential information about the primary ingredients."

    chat = RubyLLM.chat

    meal_extractor = MealExtractor.new(meal)

    chat.with_tool(meal_extractor)
    chat.add_message role: :system, content: instruction_text

    user_message = meal.prompt || "Analyze this meal:"

    chat.ask user_message, with: { image: meal.image_path }
  end

  def analyze_nutrition(user_profile:, summary_data:, meal_data:)
    prompt_template = ApplicationController.renderer.render(
      partial: "templates/nutrition_analysis_prompt",
      locals: { user_profile:, summary_data:, meal_data: }
    )

    puts prompt_template

    chat = RubyLLM.chat

    response = chat.ask prompt_template

    response.content
  end
end
