class Meal < ApplicationRecord
  has_one_attached :image# Add any validations or callbacks if needed
end
