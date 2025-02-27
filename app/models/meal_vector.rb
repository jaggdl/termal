class MealVector < ApplicationRecord
  self.primary_key = "meal_id"

  has_neighbors :embedding, dimensions: 1536

  belongs_to :meal, optional: true
end
