# frozen_string_literal: true

module Api
  class UserProfileSerializer
    include ActiveModel::Serializers::JSON

    def initialize(user_profile)
      @user_profile = user_profile
    end

    def attributes
      {
        "age" => nil,
        "weight" => nil,
        "sex" => nil,
        "timezone" => nil,
        "height" => nil,
        "fitness_goals" => nil
      }
    end

    def age
      @user_profile.age
    end

    def weight
      @user_profile.weight
    end

    def sex
      @user_profile.sex
    end

    def timezone
      @user_profile.timezone
    end

    def height
      @user_profile.height
    end

    def fitness_goals
      {
        "physical_activity" => @user_profile.physical_activity,
        "weight_goals" => @user_profile.weight_goals,
        "muscle_building" => @user_profile.muscle_building
      }
    end
  end
end
