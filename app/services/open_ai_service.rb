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

  def analyze_meal_image(base64_image, prompt = nil)
    instruction_text = "Analyze this meal image and provide brief information including nutritional content, meal name, and a very concise description of the meal (max 15 words). Only include the most essential information about the primary ingredients."

    messages = [
      {
        role: "user",
        content: [
          {
            type: "text",
            text: instruction_text
          },
          {
            type: "image_url",
            image_url: {
              url: base64_image
            }
          }
        ]
      }
    ]

    if prompt
      # Add the user's prompt before our instructions
      instruction_with_prompt = "User description: #{prompt}\n\n#{instruction_text}"
      messages.first[:content][0] = { type: "text", text: instruction_with_prompt }
    end

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

  # Analyze meals based on text prompt only
  def analyze_meal_text(prompt)
    # Default to generic meal if no prompt is provided
    prompt ||= "A basic meal"

    messages = [
      {
        role: "user",
        content: [
          {
            type: "text",
            text: "Analyze this meal description and provide brief information including nutritional content: #{prompt}\n\nPlease make sure to include a very concise description of the meal (max 15 words), mentioning only the most essential information about primary ingredients."
          }
        ]
      }
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

  # Analyze nutritional data for the past 7 days
  def analyze_nutrition(analysis_data)
    # Add date_param to the chart_data nutrients if not already present
    unless analysis_data[:nutritional_data][:chart_data][:nutrients][:date_param]
      dates = analysis_data[:nutritional_data][:chart_data][:dates]

      # Create date_param array from dates if possible
      if dates.is_a?(Array) && dates.first.is_a?(String)
        begin
          date_params = []
          dates.each do |date_str|
            # Try to parse dates like "Mar 05" into full dates
            month_abbr = date_str.split(" ").first
            day = date_str.split(" ").last.to_i
            month = Date::ABBR_MONTHNAMES.index(month_abbr)
            year = Time.current.year
            date_params << Date.new(year, month, day).strftime("%Y-%m-%d")
          end
          analysis_data[:nutritional_data][:chart_data][:nutrients][:date_param] = date_params
        rescue => e
          Rails.logger.error("Error creating date_param: #{e.message}")
        end
      end
    end

    # Render the analysis prompt template
    prompt_template = ApplicationController.renderer.render(
      partial: "templates/nutrition_analysis_prompt",
      locals: { analysis_data: analysis_data }
    )

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
        model: "gpt-4o",
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
