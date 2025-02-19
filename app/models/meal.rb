class Meal < ApplicationRecord
  has_many :user_meals, dependent: :destroy
  has_many :users, through: :user_meals
  has_one_attached :image
end
