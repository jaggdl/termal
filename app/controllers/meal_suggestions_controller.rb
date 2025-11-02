class MealSuggestionsController < ApplicationController
  def index
    @date = params[:date]&.to_date || Date.current
    @suggestion_sets = MealSuggestionsService.new(user: Current.user, date: @date).generate_suggestions

    respond_to do |format|
      format.turbo_stream
    end
  end
end
