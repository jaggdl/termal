class MealPeriod
  attr_reader :label, :icon

  def initialize(label:, icon:, hour_range:)
    @label = label
    @icon = icon
    @hour_range = hour_range
  end

  def to_s
    label
  end

  def parameterize
    label.parameterize
  end

  def self.all
    PERIODS
  end

  def self.labels
    PERIODS.map(&:label)
  end

  def self.for_hour(hour)
    PERIODS.find { |period| period.hour_range&.cover?(hour) } || PERIODS.last
  end

  PERIODS = [
    new(label: "Breakfast", icon: "sun", hour_range: 4...11),
    new(label: "Lunch", icon: "clock", hour_range: 11...16),
    new(label: "Dinner", icon: "moon", hour_range: 16...21),
    new(label: "Snack", icon: "cake", hour_range: nil)
  ].freeze

  private

  attr_reader :hour_range
end
