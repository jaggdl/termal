class UserMealsController < ApplicationController
  include LlmApiKeyCheck

  before_action :set_meal, only: [ :update, :destroy ]
  before_action :check_api_key, only: [ :new, :create ]

  def index
    @date = params[:date] ? Date.parse(params[:date]) : Current.user.user_today

    @meals = Current.user.user_meals_on_date(@date)
    @meals_by_period = Current.user.group_meals_by_period(@meals)
    @meals_by_day = { @date => @meals }
    @total_meals_count = Current.user.meals.count
    @suggestions = Meal.most_common_meals(user: Current.user, limit: 15)
  end

  def new
    @user_meal = UserMeal.new
    @date = params[:date]
  end

  def update
    if @user_meal.update(user_meal_params)
      redirect_to user_meals_path(date: @user_meal.date_consumed), notice: "Meal updated successfully."
    else
      redirect_to user_meals_path, alert: "Failed to update meal."
    end
  end

  def retry_processing
    @user_meal = Current.user_meals.find(params[:id])
    @user_meal.retry_processing!

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "user-meal-#{@user_meal.id}",
          partial: "user_meals/meal_info",
          locals: { user_meal: @user_meal }
        )
      end
      format.html { redirect_to user_meals_path(date: @user_meal.date_consumed), notice: "Processing meal again..." }
    end
  end

  def destroy
    date = @user_meal.date_consumed
    if @user_meal.destroy
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.remove("user-meal-item-#{@user_meal.id}"),
            turbo_stream.replace(
              "nutrient-meters-#{date}",
              partial: "shared/nutrient_meters",
              locals: { user_meals: Current.user.user_meals_on_date(date), date: date, user_profile: Current.user_profile }
            )
          ]
        end
        format.html { redirect_to user_meals_path(date: date), notice: "Meal was successfully removed." }
      end
    else
      redirect_to user_meals_path, alert: "Failed to remove meal."
    end
  end

  def create
    return create_from_meal_id if params[:meal_id]

    unless params[:user_meal][:files].present? || params[:user_meal][:prompt].present?
      render_flash_message("Please provide either images or a meal description.") and return
    end

    @user_meal = UserMeal.create_from_params(
      user: Current.user,
      date: params[:date],
      prompt: params[:user_meal][:prompt],
      files: params[:user_meal][:files],
      latitude: Current.latitude,
      longitude: Current.longitude
    )

    if @user_meal.persisted?
      redirect_to user_meals_path(date: @user_meal.date_consumed), notice: "Meal was successfully created."
    else
      render :new, alert: "Something went wrong :( ..."
    end
  end

  private

  def set_meal
    @user_meal = Current.user_meals.find(params[:id])
  end

  def user_meal_params
    params.require(:user_meal).permit(:consumed_at, :latitude, :longitude)
  end

  def render_flash_message(message, fallback_action = nil, alert_type = :alert)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "flash",
          partial: "shared/flash",
          locals: { flash: { alert_type => message } }
        )
      end

      if fallback_action
        format.html { render fallback_action, alert: message }
      else
        format.html { redirect_to new_user_meal_path, alert: message }
      end
    end
  end

  def create_from_meal_id
    @user_meal = Current.user.build_user_meal(meal_id: params[:meal_id], date: params[:date], consumed_at: params[:consumed_at])

    if Current.latitude.present? && Current.longitude.present?
      @user_meal.latitude = Current.latitude
      @user_meal.longitude = Current.longitude
    end

    if @user_meal.save
      date = @user_meal.date_consumed
      meals = Current.user.user_meals_on_date(date)

      render turbo_stream: [
        turbo_stream.replace(
          "day-meals-#{date}",
          partial: "user_meals/day_meals",
          locals: { date: date, meals_by_period: Current.user.group_meals_by_period(meals) }
        ),
        turbo_stream.replace(
          "flash",
          partial: "shared/flash",
          locals: { flash: { notice: "Meal successfully added" } }
        ),
        turbo_stream.replace(
          "nutrient-meters-#{date}",
          partial: "shared/nutrient_meters",
          locals: { user_meals: meals, date: date, user_profile: Current.user_profile }
        )
      ]
    else
      render_flash_message("Something went wrong. Please try again", :new, :alert)
    end
  end
end
