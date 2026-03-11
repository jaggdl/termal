module Api
  class UserMealsController < BaseController
    def index
      date = params[:date] ? Date.parse(params[:date]) : Current.user.user_today

      user_meals = Current.user.user_meals_on_date(date).includes(:meal)

      render json: UserMealsResponseSerializer.new(date, user_meals)
    rescue ArgumentError
      render json: { error: "Invalid date format" }, status: :bad_request
    end
  end
end
