# frozen_string_literal: true

module Api
  class UserMealSerializer
    include ActiveModel::Serializers::JSON

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
      meal = @user_meal.meal
      {
        "id" => meal.id,
        "name" => meal.meal_name,
        "description" => meal.description,
        "calories" => meal.calories,
        "proteins" => meal.proteins,
        "carbs" => meal.carbs,
        "fats" => meal.fats
      }
    end
  end
end
