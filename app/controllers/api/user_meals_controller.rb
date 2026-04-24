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

    def create
      meal = Meal.find(params[:meal_id])
      user_meal = Current.user.build_user_meal(meal: meal, date: params[:date], time: params[:time])

      if user_meal.save
        render json: UserMealSerializer.new(user_meal), status: :created
      else
        render json: { error: user_meal.errors.full_messages.join(", ") }, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Meal not found" }, status: :not_found
    rescue ArgumentError => e
      render json: { error: e.message }, status: :bad_request
    end

    def update
      user_meal = Current.user.user_meals.find(params[:id])
      update_attrs = user_meal_params.to_h

      if update_attrs[:consumed_at].present?
        update_attrs[:consumed_at] = parse_consumed_at_in_timezone(update_attrs[:consumed_at])
      end

      if user_meal.update(update_attrs)
        render json: UserMealSerializer.new(user_meal)
      else
        render json: { error: user_meal.errors.full_messages.join(", ") }, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotFound
      render json: { error: "User meal not found" }, status: :not_found
    rescue ArgumentError => e
      render json: { error: e.message }, status: :bad_request
    end

    def destroy
      user_meal = Current.user.user_meals.find(params[:id])
      user_meal.destroy
      head :no_content
    rescue ActiveRecord::RecordNotFound
      render json: { error: "User meal not found" }, status: :not_found
    end

    private

    def user_meal_params
      params.require(:user_meal).permit(:consumed_at, :latitude, :longitude)
    end

    def parse_consumed_at_in_timezone(datetime_string)
      tz = ActiveSupport::TimeZone[Current.user.user_profile.timezone]
      parsed = Time.parse(datetime_string)
      tz.local(parsed.year, parsed.month, parsed.day, parsed.hour, parsed.min, parsed.sec)
    rescue ArgumentError
      raise ArgumentError, "Invalid datetime format. Use ISO 8601 format (e.g., 2026-04-24T14:30:00)"
    end
  end
end
