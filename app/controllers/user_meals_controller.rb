require "mini_magick"
require "tempfile"

class UserMealsController < ApplicationController
  include ApiKeyCheck

  before_action :set_meal, only: [ :show, :update, :destroy ]
  before_action :check_api_key, only: [ :new, :create ]

  def index
    user_timezone = Current.user_profile.timezone
    tz = ActiveSupport::TimeZone[user_timezone]

    local_now = Time.current.in_time_zone(tz)
    @today = local_now.to_date
    @yesterday = @today - 1.day

    @date = params[:date] ? Date.parse(params[:date]) : @today

    local_start = tz.local(@date.year, @date.month, @date.day, 0, 0, 0)
    local_end = tz.local(@date.year, @date.month, @date.day, 23, 59, 59)

    @meals = Current.user_meals.where(consumed_at: local_start..local_end).order(consumed_at: :desc)
    @meals_by_day = { @date => @meals }
  end

  def new
    @user_meal = UserMeal.new
    @date = params[:date]
  end

  def show
    @user_profile = Current.user_profile
  end

  def update
    if @user_meal.update(user_meal_params)
      respond_to do |format|
        format.html { redirect_to user_meals_path(date: @user_meal.date_consumed), notice: "Meal updated successfully." }
      end
    else
      render :show, status: :unprocessable_entity
    end
  end

  def retry_processing
    @user_meal = Current.user_meals.find(params[:id])
    @user_meal.update(error: nil)

    ProcessMealImageJob.perform_later(@user_meal.id)

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
      redirect_to user_meals_path(date: date), notice: "Meal was successfully removed."
    else
      redirect_to user_meal_path(@user_meal), alert: "Failed to remove meal."
    end
  end

  def create
    return create_from_meal_id if params[:meal_id]

    unless params[:user_meal][:files].present? || params[:user_meal][:prompt].present?
      render_flash_message("Please provide either images or a meal description.") and return
    end

    consumed_at = calculate_consumed_at(params[:date])
    @user_meal = Current.user.user_meals.build(consumed_at: consumed_at)

    if params[:user_meal][:latitude].present? && params[:user_meal][:longitude].present?
      @user_meal.latitude = params[:user_meal][:latitude]
      @user_meal.longitude = params[:user_meal][:longitude]
    end

    prompt = params[:user_meal][:prompt]
    @meal = @user_meal.build_meal(prompt: prompt)

    images_files = params[:user_meal][:files]

    if images_files.present?
      @meal.images.attach(images_files)
    end

    begin
      if @user_meal.save
        ProcessMealImageJob.perform_later(@user_meal.id)
        redirect_to user_meals_path(date: @user_meal.date_consumed), notice: "Meal was successfully created."
      else
        render :new, alert: "Something went wrong :( ..."
      end
    rescue => e
      Rails.logger.error("Error in MealsController#create: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      render_flash_message("An unexpected error occurred. Please try again.", :new)
    end
  end

  private

  def set_meal
    @user_meal = Current.user_meals.find(params[:id])
  end

  def user_meal_params
    params.require(:user_meal).permit(:consumed_at)
  end

  def calculate_consumed_at(date_param)
    if date_param.present? && !Current.user.user_date_is_today?(date_param)
      date = Date.parse(date_param)
      user_timezone = Current.user_profile.timezone
      tz = ActiveSupport::TimeZone[user_timezone]
      tz.local(date.year, date.month, date.day, 23, 59, 59)
    else
      Time.now
    end
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
    meal_id = params[:meal_id]
    consumed_at = calculate_consumed_at(params[:date])
    @user_meal = Current.user_meals.new(meal_id: meal_id, consumed_at: consumed_at)

    if params[:latitude].present? && params[:longitude].present?
      @user_meal.latitude = params[:latitude]
      @user_meal.longitude = params[:longitude]
    end

    if @user_meal.save
      date = @user_meal.date_consumed

      render turbo_stream: [
        turbo_stream.prepend(
          "user-meals-#{date}",
          partial: "user_meals/user_meal",
          locals: { user_meal: @user_meal }
        ),
        turbo_stream.remove("no-meals-message"),
        turbo_stream.replace(
          "flash",
          partial: "shared/flash",
          locals: { flash: { notice: "Meal successfully added" } }
        ),
        turbo_stream.replace(
          "nutrient-meters-#{date}",
          partial: "shared/nutrient_meters",
          locals: { user_meals: Current.user.user_meals_on_date(date), date: date, user_profile: Current.user_profile }
        )
      ]
    else
      render_flash_message("Something went wrong. Please try again", :new, :alert)
    end
  end
end
