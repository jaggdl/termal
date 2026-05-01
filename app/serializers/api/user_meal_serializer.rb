# frozen_string_literal: true

module Api
  class UserMealSerializer
    include ActiveModel::Serializers::JSON
    include Rails.application.routes.url_helpers

    def initialize(user_meal)
      @user_meal = user_meal
    end

    def attributes
      {
        "id" => nil,
        "consumed_at" => nil,
        "date_consumed" => nil,
        "time_consumed" => nil,
        "error" => nil,
        "error_message" => nil,
        "meal" => nil
      }
    end

    def id
      @user_meal.id
    end

    def consumed_at
      @user_meal.consumed_at
    end

    def date_consumed
      @user_meal.date_consumed
    end

    def time_consumed
      @user_meal.time_consumed
    end

    def error
      @user_meal.error
    end

    def error_message
      @user_meal.error_message
    end

    def meal
      MealSerializer.new(@user_meal.meal).as_json
    end
  end
end
