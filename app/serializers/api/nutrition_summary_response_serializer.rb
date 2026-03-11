# frozen_string_literal: true

module Api
  class NutritionSummaryResponseSerializer
    include ActiveModel::Serializers::JSON

    def initialize(daily_summaries, user_profile, days)
      @daily_summaries = daily_summaries
      @user_profile = user_profile
      @days = days
    end

    def attributes
      {
        "summaries" => nil,
        "targets" => nil,
        "averages" => nil
      }
    end

    def summaries
      @daily_summaries.map do |summary|
        {
          "date" => summary[:date].iso8601,
          "calories" => summary[:calories],
          "proteins" => summary[:proteins],
          "carbs" => summary[:carbs],
          "fats" => summary[:fats]
        }
      end
    end

    def targets
      daily_targets = @user_profile.daily_targets
      {
        "calories" => daily_targets[:calories],
        "proteins" => daily_targets[:proteins],
        "carbs" => daily_targets[:carbs],
        "fats" => daily_targets[:fats]
      }
    end

    def averages
      return nil if @daily_summaries.empty?

      total_calories = @daily_summaries.sum { |s| s[:calories] }
      total_proteins = @daily_summaries.sum { |s| s[:proteins] }
      total_carbs = @daily_summaries.sum { |s| s[:carbs] }
      total_fats = @daily_summaries.sum { |s| s[:fats] }
      count = @daily_summaries.size

      daily_targets = @user_profile.daily_targets

      avg_calories = total_calories.to_f / count
      avg_proteins = total_proteins / count
      avg_carbs = total_carbs / count
      avg_fats = total_fats / count

      {
        "calories" => {
          "quantity" => avg_calories.round(1),
          "percentage_of_target" => calculate_percentage(avg_calories, daily_targets[:calories])
        },
        "proteins" => {
          "quantity" => avg_proteins.round(1),
          "percentage_of_target" => calculate_percentage(avg_proteins, daily_targets[:proteins])
        },
        "carbs" => {
          "quantity" => avg_carbs.round(1),
          "percentage_of_target" => calculate_percentage(avg_carbs, daily_targets[:carbs])
        },
        "fats" => {
          "quantity" => avg_fats.round(1),
          "percentage_of_target" => calculate_percentage(avg_fats, daily_targets[:fats])
        }
      }
    end

    private

    def calculate_percentage(value, target)
      return 0 if target.nil? || target == 0
      ((value / target.to_f) * 100).round(1)
    end
  end
end
