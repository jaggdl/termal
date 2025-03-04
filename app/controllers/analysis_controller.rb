class AnalysisController < ApplicationController
  def show
    # Get period from params or default to 7 days
    @period = 7

    # Use our nutrition summary service to get all data
    @summary = NutritionSummaryService.new(Current.user, period: @period).summary_data

    # Check if we have a stored analysis
    @analysis = GlobalSetting.get("user_#{Current.user.id}_nutrition_analysis")
    @analysis_timestamp = GlobalSetting.get("user_#{Current.user.id}_nutrition_analysis_timestamp")

    # Convert timestamp to Time object if it exists
    @analysis_time = Time.parse(@analysis_timestamp) if @analysis_timestamp.present?
  end

  def create
    streaming = params[:streaming].present? && params[:streaming] == "true"

    if streaming
      # Queue the job to analyze nutrition data with streaming
      AnalyzeNutritionJob.perform_later(Current.user.id)

      respond_to do |format|
        format.html { render :stream }
        format.turbo_stream do
          flash.now[:notice] = "Analyzing your nutrition data..."
          render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash", locals: { flash: flash })
        end
      end
    else
      # Standard non-streaming approach
      AnalyzeNutritionJob.perform_later(Current.user.id)

      respond_to do |format|
        format.html do
          flash[:notice] = "Nutritional analysis has been queued and will be available shortly."
          redirect_to analysis_path
        end
        format.turbo_stream do
          flash.now[:notice] = "Nutritional analysis has been queued and will be available shortly."
          render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash", locals: { flash: flash })
        end
      end
    end
  end

  def stream
    # This action is used when the user refreshes the page during streaming
    @stream_id = params[:stream_id]
    render :stream
  end
end
