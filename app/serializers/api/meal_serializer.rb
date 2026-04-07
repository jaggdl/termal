# frozen_string_literal: true

module Api
  class MealSerializer
    include ActiveModel::Serializers::JSON
    include ApplicationHelper

    def initialize(meal)
      @meal = meal
    end

    def attributes
      {
        "id" => nil,
        "url" => nil,
        "name" => nil,
        "description" => nil,
        "calories" => nil,
        "proteins" => nil,
        "carbs" => nil,
        "fats" => nil,
        "created_at" => nil
      }
    end

    def url
      "#{base_url}/meals/#{@meal.id}"
    end

    def id
      @meal.id
    end

    def name
      @meal.meal_name
    end

    def description
      @meal.description
    end

    def calories
      @meal.calories
    end

    def proteins
      @meal.proteins
    end

    def carbs
      @meal.carbs
    end

    def fats
      @meal.fats
    end

    def created_at
      @meal.created_at.iso8601
    end
  end
end
