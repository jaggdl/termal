class NutritionAnalysis < ApplicationRecord
  belongs_to :user

  validates :text, :executed_at, presence: true

  # Broadcasts to the client when the record changes
  # This enables the turbo_stream to update when the analysis completes
  broadcasts_to ->(analysis) { [ analysis.user, "analyses" ] }, inserts_by: :replace

  def formatted_date_range
    "#{date_start.strftime('%b %d')} - #{date_end.strftime('%b %d')}"
  end

  def period
    (date_end - date_start).to_i + 1
  end

  def offset
    (user.user_today - date_end).to_i
  end

  def pending?
    status == "pending"
  end

  def completed?
    status == "completed"
  end
end
