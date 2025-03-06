class NutritionAnalysis < ApplicationRecord
  belongs_to :user

  validates :text, :date_start, :date_end, :executed_at, presence: true

  def formatted_date_range
    "#{date_start.strftime('%b %d')} - #{date_end.strftime('%b %d')}"
  end
end
