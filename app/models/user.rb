class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_one :user_profile
  has_many :user_meals, dependent: :destroy
  has_many :meals, through: :user_meals

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  def user_meals_on_date(date)
    timezone = user_profile.timezone
    start_of_day = date.in_time_zone(timezone).beginning_of_day
    end_of_day = date.in_time_zone(timezone).end_of_day
    user_meals.where(consumed_at: start_of_day..end_of_day)
  end
end
