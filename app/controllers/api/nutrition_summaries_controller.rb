# frozen_string_literal: true

module Api
  class NutritionSummariesController < BaseController
    def index
      days = params[:days]&.to_i || 7
      days = [ days, 365 ].min # Cap at 1 year to prevent abuse

      end_date = Current.user.user_today
      start_date = end_date - days.days

      daily_summaries = Current.user.daily_nutrition_summaries(start_date, end_date)
      user_profile = Current.user.user_profile

      render json: NutritionSummaryResponseSerializer.new(daily_summaries, user_profile, days)
    end
  end
end
