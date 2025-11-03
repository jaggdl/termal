class MealSuggestionsController < ApplicationController
  def index
    @date = params[:date] ? Date.parse(params[:date]) : Current.user.user_today
    @suggestion_set = MealSuggestionsService.new(user: Current.user, date: @date).generate_suggestions

    respond_to do |format|
      format.turbo_stream
    end
  end
end
