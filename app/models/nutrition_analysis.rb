class NutritionAnalysis < ApplicationRecord
  belongs_to :user

  validates :text, :executed_at, presence: true

  # Broadcasts to the client when the record changes
  # This enables the turbo_stream to update when the analysis completes
  broadcasts_to ->(analysis) { [ analysis.user, "analyses" ] }, inserts_by: :replace

  def formatted_date_range
    return "Custom analysis" if date_start.nil? || date_end.nil?
    "#{date_start.strftime('%b %d')} - #{date_end.strftime('%b %d')}"
  end

  def pending?
    status == "pending"
  end

  def completed?
    status == "completed"
  end
end
