# Calories Tracker Development Guide

## Commands
- **Server**: `bin/dev` - Run development server
- **Brakeman**: `bin/brakeman` - Run security analysis
- **Console**: `bin/rails console` - Rails console

Please don't bother executing tests. I will do it myself.

## Code Style
- **Ruby**: Follow Rails Omakase (RuboCop) style guide
- **Models**: Business logic in models, validations first, then callbacks, methods
- **Controllers**: RESTful actions, thin controllers (business logic in models)
- **Naming**: snake_case for variables/methods, CamelCase for classes
- **Errors**: Use Rails exceptions, rescue in controllers
- **HTML/ERB**: Use Tailwind CSS for styling
- **JavaScript**: Use Stimulus.js for interactive elements
- **Testing**: Test models and controllers, focus on happy paths + edge cases
- **Icons**: This project uses the heroicons gem. Here's an example of the usage: `<%= heroicon "magnifying-glass", options: { class: "text-primary-500" } %>` 

This project is a Ruby on Rails application for tracking calories and meals.

## Error Handling

Error codes are managed through the `ErrorMessages` concern. When adding new error types:

1. Add the error code and message to `ERROR_CODES` hash in `app/models/concerns/error_messages.rb`
2. In job classes, store error codes using `handle_error(object, :error_code)`
3. Error messages are displayed using the `error_message` method which translates error codes to human-readable messages
