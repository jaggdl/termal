# Configure RubyLLM
require "ruby_llm"

# Global configuration for RubyLLM
RubyLLM.configure do |config|
  # Default configuration is set, but the API key will be set in the OpenAiService
  # to ensure it's always using the most up-to-date key from GlobalSettings
end
