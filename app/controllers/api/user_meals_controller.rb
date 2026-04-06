module Api
  class UserMealsController < BaseController
    def index
      date = params[:date] ? Date.parse(params[:date]) : Current.user.user_today

      user_meals = Current.user.user_meals_on_date(date).includes(:meal)

      render json: UserMealsResponseSerializer.new(date, user_meals)
    rescue ArgumentError
      render json: { error: "Invalid date format" }, status: :bad_request
    end

    def create
      meal = Meal.find(params[:meal_id])
      user_meal = Current.user.user_meals.build(
        meal: meal,
        consumed_at: params[:datetime] ? Time.zone.parse(params[:datetime]) : Time.current
      )

      if user_meal.save
        render json: UserMealSerializer.new(user_meal), status: :created
      else
        render json: { errors: user_meal.errors.full_messages }, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Meal not found" }, status: :not_found
    rescue ArgumentError
      render json: { error: "Invalid datetime format" }, status: :bad_request
    end

    def show
      user_meal = Current.user.user_meals.find(params[:id])
      render json: UserMealSerializer.new(user_meal)
    rescue ActiveRecord::RecordNotFound
      render json: { error: "User meal not found" }, status: :not_found
    end
  end
end
