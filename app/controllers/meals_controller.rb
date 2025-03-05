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

  def search
    if params[:q].present?
      @meals = Meal.vector_search(query: params[:q], user: Current.user, limit: 10)
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
