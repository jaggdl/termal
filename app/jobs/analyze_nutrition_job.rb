class AnalyzeNutritionJob < ApplicationJob
  queue_as :default

  def perform(user_id, stream: nil)
    # Get the user
    user = User.find_by(id: user_id)
    return unless user

    # Get the summary data for the user
    summary = NutritionSummaryService.new(user, period: 7).summary_data

    # Check if OpenAI API key is set
    return unless GlobalSetting.get("openai_api_key").present?

    # Initialize OpenAI service
    openai_service = OpenAiService.new
    user_profile = user.user_profile

    # Create analysis data
    analysis_data = {
      user_profile: {
        gender: user_profile.sex,
        age: user_profile.age,
        weight: user_profile.weight,
        height: user_profile.height,
        activity_level: user_profile.physical_activity,
        muscle_building: user_profile.muscle_building,
        weight_goals: user_profile.weight_goals,
        daily_targets: user_profile.daily_targets
      },
      nutritional_data: summary
    }

    # Stream analysis with broadcasting
    full_analysis = ""

    openai_service.stream_analyze_nutrition(analysis_data) do |chunk|
      if chunk.present?
        # Add the chunk to our full analysis
        full_analysis += chunk.to_s

        # Broadcast the full analysis so far as HTML rendered from markdown
        Turbo::StreamsChannel.broadcast_update_to(
          [ user, "nutrition_analysis" ],
          target: "nutrition_analysis_content",
          html: ApplicationController.helpers.markdown(full_analysis)
        )
      end
    end

    # Save the completed analysis
    user_analysis_key = "user_#{user_id}_nutrition_analysis"
    GlobalSetting.set(user_analysis_key, full_analysis)

    # Also save the timestamp
    analysis_timestamp_key = "user_#{user_id}_nutrition_analysis_timestamp"
    GlobalSetting.set(analysis_timestamp_key, Time.current.iso8601)

    # Signal completion
    Turbo::StreamsChannel.broadcast_update_to(
      [ user, "nutrition_analysis" ],
      target: "nutrition_analysis_status",
      html: "<div class='text-sm text-gray-500'>Analysis completed</div>"
    )
  rescue StandardError => e
    Rails.logger.error("Error in AnalyzeNutritionJob for user #{user_id}: #{e.message}")
    if user
      Turbo::StreamsChannel.broadcast_update_to(
        [ user, "nutrition_analysis" ],
        target: "nutrition_analysis_status",
        html: "<div class='text-sm text-red-500'>Error: #{e.message}</div>"
      )
    end
  end
end
