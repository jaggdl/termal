class OpenAiService
  def initialize
    @client = OpenAI::Client.new(
      access_token: ENV["OPENAI_API_KEY"],
      log_errors: true
    )
  end

  def analyze_meal_image(base64_image)
    messages = [
      {
        role: "user",
        content: [
          {
            type: "text",
            text: "Analyze this meal image and provide nutritional information including the meal name."
          },
          {
            type: "image_url",
            image_url: {
              url: "data:image/webp;base64,#{base64_image}"
            }
          }
        ]
      }
    ]

    response = @client.chat(
      parameters: {
        model: "gpt-4o",
        messages: messages,
        tools: [
          {
            type: "function",
            function: {
              name: "extract_meal_info",
              description: "Extract nutritional information and meal name from an image",
              parameters: {
                type: :object,
                properties: {
                  meal_name: {
                    type: :string,
                    description: "The name or description of the meal"
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
        ],
        tool_choice: "required"
      }
    )

    extract_meal_data(response)
  end

  private

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
