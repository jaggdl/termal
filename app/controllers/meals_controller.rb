class MealsController < ApplicationController
  include ApiKeyCheck

  before_action :set_meal, only: [ :show, :update ]
  before_action :check_api_key, only: [ :new ]

  def index
    @meals_by_day = Meal.all.order(consumed_at: :desc).group_by do |meal|
      meal.consumed_at.in_time_zone(@timezone).to_date
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
    @meal = Meal.find(params[:id])
    if @meal.destroy
      redirect_to meals_path, notice: "Meal was successfully deleted."
    else
      redirect_to meals_path, alert: "Failed to delete meal."
    end
  end

  def create
    unless params[:meal][:file]
      redirect_to new_meal_path, alert: "No file uploaded." and return
    end

    meal_data = process_meal_image(params[:meal][:file], params[:meal][:prompt])

    unless meal_data
      redirect_to new_meal_path, alert: "Failed to extract meal information." and return
    end

    @meal = create_meal_from_data(meal_data)
    @meal.image.attach(params[:meal][:file])

    if @meal.save
      redirect_to meals_path, notice: "Meal was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_meal
    @meal = Meal.find(params[:id])
  end

  def meal_params
    params.require(:meal).permit(:meal_name, :calories, :fats, :proteins, :carbs, :fiber, :sodium, :sugar, :cholesterol, :consumed_at)
  end

  def process_meal_image(file, prompt)
    image_data = file.read
    webp_image = convert_image_to_webp(image_data)

    base64_image = Base64.strict_encode64(webp_image)
    openai_service = OpenAiService.new
    openai_service.analyze_meal_image(base64_image, prompt)
  end

  def convert_image_to_webp(image_data)
    tempfile = Tempfile.new([ "meal_image", ".jpg" ])
    tempfile.binmode
    tempfile.write(image_data)
    tempfile.rewind

    webp_image = ImageProcessing::MiniMagick.source(tempfile).convert("webp").call

    webp_image.read
  ensure
    tempfile.close
    tempfile.unlink
  end

  def create_meal_from_data(meal_data)
    Meal.new(
      meal_name: meal_data[:meal_name],
      consumed_at: Time.now,
      calories: meal_data[:calories],
      fats: meal_data[:fats],
      proteins: meal_data[:proteins],
      carbs: meal_data[:carbs],
      fiber: meal_data[:fiber],
      sodium: meal_data[:sodium],
      sugar: meal_data[:sugar],
      cholesterol: meal_data[:cholesterol],
    )
  end
end
