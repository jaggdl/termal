# Calories Tracker Development Guide

## Commands
- **Server**: `bin/dev` - Run development server
- **Tests**: `bin/rails test` - Run all tests
- **Single Test**: `bin/rails test TEST=test/models/user_test.rb` - Run specific test
- **Linter**: `bin/rubocop` - Run RuboCop linter
- **Brakeman**: `bin/brakeman` - Run security analysis
- **Console**: `bin/rails console` - Rails console

## Code Style
- **Ruby**: Follow Rails Omakase (RuboCop) style guide
- **Models**: Business logic in models, validations first, then callbacks, methods
- **Controllers**: RESTful actions, thin controllers (business logic in models)
- **Naming**: snake_case for variables/methods, CamelCase for classes
- **Errors**: Use Rails exceptions, rescue in controllers
- **HTML/ERB**: Use Tailwind CSS for styling
- **JavaScript**: Use Stimulus.js for interactive elements
- **Testing**: Test models and controllers, focus on happy paths + edge cases

This project is a Ruby on Rails application for tracking calories and meals.