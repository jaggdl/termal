class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_one :user_profile
  has_many :meals

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
