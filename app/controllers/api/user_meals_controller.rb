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
      user_meal = Current.user.build_user_meal(meal: meal, consumed_at: params[:consumed_at], date: params[:date])

      if user_meal.save
        render json: UserMealSerializer.new(user_meal), status: :created
      else
        render json: { error: user_meal.errors.full_messages.join(", ") }, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Meal not found" }, status: :not_found
    end

    def update
      user_meal = Current.user.user_meals.find(params[:id])

      if user_meal.update(consumed_at: params[:consumed_at])
        render json: UserMealSerializer.new(user_meal)
      else
        render json: { error: user_meal.errors.full_messages.join(", ") }, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotFound
      render json: { error: "User meal not found" }, status: :not_found
    end

    def destroy
      user_meal = Current.user.user_meals.find(params[:id])
      user_meal.destroy
      head :no_content
    rescue ActiveRecord::RecordNotFound
      render json: { error: "User meal not found" }, status: :not_found
    end
  end
end
