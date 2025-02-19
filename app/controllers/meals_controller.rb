class MealsController < ApplicationController
  include ApiKeyCheck

  before_action :set_meal, only: [:show, :update, :destroy]
  before_action :check_api_key, only: [:new, :create]

  def index
    @meals_by_day = Current.user.meals.all.order(consumed_at: :desc).group_by do |meal|
      meal.consumed_at_in_timezone.to_date
    end
  end

  def new
    @meal = Meal.new
  end

  def show
  end

  def update
    if @meal.update(meal_params)
      respond_to do |format|
        format.html { redirect_to meals_path, notice: "Meal updated successfully." }
      end
    else
      render :show, status: :unprocessable_entity
    end
  end

  def destroy
    if @meal.destroy
      redirect_to meals_path, notice: "Meal was successfully deleted."
    else
      redirect_to meals_path, alert: "Failed to delete meal."
    end
  end

  def create
    unless params[:meal][:file].present?
      redirect_to new_meal_path, alert: "No image data provided." and return
    end
  
    @meal = Current.user.meals.new(
      consumed_at: Time.now,
      meal_name: "New meal"
    )
  
    begin
      if params[:meal][:file].present?
        @meal.image.attach(params[:meal][:file])
      end
  
      if @meal.save
        ProcessMealImageJob.perform_later(@meal.id, params[:meal][:prompt])
        redirect_to meals_path, notice: "Meal was successfully created."
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
    @meal = Current.user.meals.find(params[:id])
  end

  def meal_params
    params.require(:meal).permit(:meal_name, :calories, :fats, :proteins, :carbs, :fiber, :sodium, :sugar, :cholesterol, :consumed_at)
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
end
