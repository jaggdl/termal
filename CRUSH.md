# Termal Development Guide

## Commands
- **Server**: `bin/dev` - Run development server with Tailwind CSS
- **Console**: `bin/rails console` - Rails console
- **Security**: `bin/brakeman` - Run security analysis
- **Lint**: `bin/rubocop` - Run RuboCop linter
- **Lint Fix**: `bin/rubocop -a` - Auto-fix RuboCop issues
- **Test All**: `bin/rails test` - Run all tests
- **Test Single**: `bin/rails test test/models/user_test.rb` - Run single test file
- **Test Method**: `bin/rails test test/models/user_test.rb -n test_method_name` - Run single test method

## Code Style
- **Ruby**: Follow Rails Omakase (RuboCop) style guide
- **Models**: Business logic in models, validations first, then callbacks, methods
- **Controllers**: RESTful actions, thin controllers (business logic in models)
- **Naming**: snake_case for variables/methods, CamelCase for classes
- **Errors**: Use Rails exceptions, rescue in controllers. Error codes managed through `ErrorMessages` concern
- **HTML/ERB**: Use Tailwind CSS for styling
- **JavaScript**: Use Stimulus.js for interactive elements
- **Icons**: Use heroicons gem: `<%= heroicon "magnifying-glass", options: { class: "text-primary-500" } %>`
- **Testing**: Test models and controllers, focus on happy paths + edge cases
- **Jobs**: Store error codes using `handle_error(object, :error_code)`
- **Imports**: Standard Rails conventions, group gems logically in Gemfile
- **Vector Search**: Uses sqlite-vec and neighbor gems for embeddings

## Key Technologies
- Rails 8.0.2, SQLite3, Puma, Turbo/Stimulus, Tailwind CSS, Heroicons
- Vector search with sqlite-vec/neighbor, LLM integration with ruby_llm
- PWA support, web push notifications, image processing