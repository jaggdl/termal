module Api
  class UserMealsController < BaseController
    def index
      date = params[:date] ? Date.parse(params[:date]) : Current.user.user_today

      user_meals = Current.user.user_meals_on_date(date).includes(:meal)

      render json: UserMealsResponseSerializer.new(date, user_meals)
    rescue ArgumentError
      render json: { error: "Invalid date format" }, status: :bad_request
    end

    def show
      user_meal = Current.user.user_meals.find(params[:id])
      render json: UserMealSerializer.new(user_meal)
    rescue ActiveRecord::RecordNotFound
      render json: { error: "User meal not found" }, status: :not_found
    end
  end
end
