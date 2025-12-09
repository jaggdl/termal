class MealsController < ApplicationController
  include ApiKeyCheck

  before_action :set_meal, only: [ :show, :update, :edit ]

  def index
    @meals_by_day = Current.user.meals.all.order(created_at: :desc).group_by do |meal|
      meal.created_at.in_time_zone(Current.user_profile.timezone).to_date
    end
  end

  def show
    @user_profile = Current.user_profile
  end

  def edit
  end

  def update
    if @meal.update(meal_params)
      redirect_to meal_path(@meal), notice: "Meal updated successfully."
    else
      redirect_to edit_meal_path(@meal), notice: "Something went wrong..."
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
    limit = 10
    query = params[:q]
    offset = params[:offset].to_i
    user = Current.user

    if query.present?
      @meals = Meal.vector_search(query:, user:, limit:, offset:)
    else
      @meals = []
    end

    respond_to do |format|
      format.html { render partial: "meals/search_results", locals: { meals: @meals, date: params[:date], query:, offset: } }
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.append("meal_list", partial: "shared/meal_list", locals: { meals: @meals, date: params[:date] }),
          turbo_stream.replace("show_more_container", partial: "meals/show_more_button", locals: { query:, date: params[:date], offset:, show_button: @meals.any? && @meals.size == limit })
        ]
      end
    end
  end

  private

  def set_meal
    @meal = Current.user.meals.find(params[:id])
  end

  def meal_params
    params.require(:meal).permit(:meal_name, :description, :calories, :fats, :proteins, :carbs, :fiber, :sodium, :sugar, :cholesterol)
  end
end
