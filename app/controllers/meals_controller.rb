class MealsController < ApplicationController
  include ApiKeyCheck

  before_action :set_meal, only: [ :show, :update, :destroy ]

  def index
    @meals_by_day = Current.user.meals.all.order(created_at: :desc).group_by do |meal|
      meal.created_at.in_time_zone(Current.user_profile.timezone).to_date
    end
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

  def normal_search
    if params[:q].present?
      @meals = Meal.normal_search(query: params[:q], limit: 2, user: Current.user)
    else
      @meals = []
    end
    # Store normal search meal IDs in session for deduplication
    session[:normal_search_meal_ids] = @meals.map(&:id).join(",")
    render partial: "meals/normal_search_results", locals: { meals: @meals, date: params[:date] }
  end

  def search
    if params[:q].present?
      normal_meal_ids = session[:normal_search_meal_ids] || []

      @meals = Meal.vector_search(query: params[:q], user: Current.user, limit: 8)
        .reject { |meal| normal_meal_ids.split(",").include?(meal.id.to_s) }
    else
      @meals = []
    end
    render partial: "meals/search_results", locals: { meals: @meals, date: params[:date] }
  end

  private

  def set_meal
    @meal = Current.user.meals.find(params[:id])
  end

  def meal_params
    params.require(:meal).permit(:meal_name, :calories, :fats, :proteins, :carbs, :fiber, :sodium, :sugar, :cholesterol)
  end
end
