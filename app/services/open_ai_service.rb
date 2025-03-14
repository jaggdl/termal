class OpenAiService
  def initialize
    @openai_api_key = GlobalSetting.get("openai_api_key")

    unless @openai_api_key
      raise StandardError, "OpenAI API key is not set. Please set it in the global settings."
    end

    @client = OpenAI::Client.new(
      access_token: @openai_api_key,
      log_errors: true
    )
  end

  def embedding(input)
    @client.embeddings(
      parameters: {
        model: "text-embedding-3-small",
        input: input
      }
    ).fetch("data")[0]["embedding"]
  end

  def analyze_meal_image(base64_image:, prompt: nil)
    instruction_text = "Analyze this meal image and provide brief information including nutritional content, meal name, and a very concise description of the meal (max 15 words). Only include the most essential information about the primary ingredients."
    user_message = {
      role: "user",
      content: []
    }

    if base64_image
      user_message[:content].append({
        type: "image_url",
        image_url: {
          url: base64_image
        }
      })
    end

    if prompt
      user_message[:content].append({
        type: "text",
        text: prompt
      })
    end

    messages = [
      {
        role: "system",
        content: [
          {
            type: "text",
            text: instruction_text
          }
        ]
      },
      user_message
    ]

    response = @client.chat(
      parameters: {
        model: "o1",
        messages: messages,
        tools: [ meal_extraction_tool ],
        tool_choice: "required"
      }
    )

    extract_meal_data(response)
  end

  def analyze_nutrition(user_profile:, summary_data:, meal_data:)
    prompt_template = ApplicationController.renderer.render(
      partial: "templates/nutrition_analysis_prompt",
      locals: { user_profile:, summary_data:, meal_data: }
    )

    puts prompt_template

    messages = [
      {
        role: "user",
        content: [
          {
            type: "text",
            text: prompt_template
          }
        ]
      }
    ]

    response = @client.chat(
      parameters: {
        model: "o1",
        messages: messages
      }
    )

    response.dig("choices", 0, "message", "content")
  end

  private

  def meal_extraction_tool
    {
      type: "function",
      function: {
        name: "extract_meal_info",
        description: "Extract nutritional information, meal name, and brief concise description from an image or text",
        parameters: {
          type: :object,
          properties: {
            meal_name: {
              type: :string,
              description: "The name or title of the meal"
            },
            description: {
              type: :string,
              description: "A very concise description of the meal (max 15 words) mentioning only essential information about primary ingredients"
            },
            calories: {
              type: :integer,
              description: "Total calories in the meal"
            },
            fats: {
              type: :number,
              description: "Total grams of fat"
            },
            proteins: {
              type: :number,
              description: "Total grams of protein"
            },
            carbs: {
              type: :number,
              description: "Total grams of carbohydrates"
            },
            fiber: {
              type: :number,
              description: "Total grams of dietary fiber"
            },
            sodium: {
              type: :number,
              description: "Total milligrams of sodium"
            },
            sugar: {
              type: :number,
              description: "Total grams of sugar"
            },
            cholesterol: {
              type: :number,
              description: "Total milligrams of cholesterol"
            }
          },
          required: [
            "meal_name",
            "description",
            "calories",
            "fats",
            "proteins",
            "carbs",
            "fiber",
            "sodium",
            "sugar",
            "cholesterol"
          ]
        }
      }
    }
  end

  def extract_meal_data(response)
    message = response.dig("choices", 0, "message")
    return nil unless message["role"] == "assistant" && message["tool_calls"]

    meal_data = nil
    messages = [ message ]

    message["tool_calls"].each do |tool_call|
      function_args = JSON.parse(tool_call.dig("function", "arguments"), { symbolize_names: true })

      if tool_call.dig("function", "name") == "extract_meal_info"
        meal_data = function_args
        messages << {
          tool_call_id: tool_call.dig("id"),
          role: "tool",
          name: "extract_meal_info",
          content: function_args.to_json
        }
      end
    end

    meal_data
  end
end
