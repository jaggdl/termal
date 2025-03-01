module ErrorMessages
  extend ActiveSupport::Concern

  ERROR_CODES = {
    invalid_openai_api_key: "Invalid OpenAI API Key",
    failed_meal_analysis: "Failed to analyze meal content",
    image_processing_error: "Failed to process image",
    not_found: "Resource not found",
    unauthorized: "Unauthorized access",
    server_error: "Internal server error"
  }.freeze

  module ClassMethods
    def error_message_for(error_code)
      ERROR_CODES[error_code.to_sym] || "An unknown error occurred"
    end
  end

  def error_message
    return nil if error.blank?
    self.class.error_message_for(error)
  end
end
