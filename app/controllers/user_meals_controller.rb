class UserMealsController < ApplicationController
  include ApiKeyCheck

  before_action :set_meal, only: [:show, :update, :destroy]
  before_action :check_api_key, only: [:new, :create]

  def index
    @meals_by_day = Current.user_meals.all.order(consumed_at: :desc).group_by do |meal|
      meal.consumed_at_in_timezone.to_date
    end
  end

  def new
    @user_meal = UserMeal.new
  end

  def show
  end

  def update
    if @user_meal.update(user_meal_params)
      respond_to do |format|
        format.html { redirect_to root_path, notice: "Meal updated successfully." }
      end
    else
      render :show, status: :unprocessable_entity
    end
  end

  def destroy
    if @user_meal.destroy
      redirect_to root_path, notice: "Meal was successfully removed."
    else
      redirect_to user_meal_path(@user_meal), alert: "Failed to remove meal."
    end
  end

  def create
    return create_from_meal_id if params[:meal_id]

    unless params[:user_meal][:file].present?
      redirect_to new_meal_path, alert: "No image data provided." and return
    end
  
    @user_meal = Current.user.user_meals.build(consumed_at: Time.now)
    @meal = @user_meal.build_meal(meal_name: "New meal")

    @meal.image.attach(params[:user_meal][:file])
  
    begin
      if @user_meal.save
        ProcessMealImageJob.perform_later(@user_meal.id, params[:user_meal][:prompt])
        redirect_to root_path, notice: "Meal was successfully created."
      else
        render :new, alert: "Something went wrong :( ..."
      end
    rescue => e
      Rails.logger.error("Error in MealsController#create: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      render :new, alert: "An unexpected error occurred. Please try again."
    end
  end

  private

  def set_meal
    @user_meal = Current.user_meals.find(params[:id])
  end

  def user_meal_params
    params.require(:user_meal).permit(:consumed_at)
  end

  def resize_and_convert_image(image)
    ImageProcessing::Vips
      .source(image)
      .resize_to_limit(1000, 1000)
      .convert('png')  # Converts to PNG
      .call
  end

  def convert_to_base64_with_mime(image)
    encoded_image = Base64.strict_encode64(File.read(image.path))
    "data:image/png;base64,#{encoded_image}"
  end

  def create_from_meal_id
    meal_id = params[:meal_id]
    @user_meal = Current.user_meals.new(meal_id: meal_id, consumed_at: Time.now)

    if @user_meal.save
      date = @user_meal.consumed_at_in_timezone.to_date

      render turbo_stream: turbo_stream.prepend(
        "user-meals-#{date.to_s}",
        partial: 'user_meals/user_meal',
        locals: { user_meal: @user_meal }
      )
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace('new_user_meal_form', partial: 'form', locals: { user_meal: @user_meal }) }
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end
end
