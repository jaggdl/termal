class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_one :user_profile, dependent: :destroy
  has_many :user_meals, dependent: :destroy
  has_many :meals, through: :user_meals
  has_many :invites, dependent: :destroy
  has_many :push_subscriptions, dependent: :destroy
  has_many :nutrition_analyses, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  # Override destroy to handle foreign key constraints properly
  def destroy
    ActiveRecord::Base.transaction do
      # First delete any user_meals (which references meals that might have meal_vectors)
      user_meals.destroy_all

      # Now we can safely destroy the user
      super
    end
  end

  def user_meals_on_date(date)
    timezone = user_profile.timezone
    start_of_day = date.in_time_zone(timezone).beginning_of_day
    end_of_day = date.in_time_zone(timezone).end_of_day
    user_meals.where(consumed_at: start_of_day..end_of_day)
  end

  def first_user?
    self.id == User.order(:id).first&.id
  end

  def can_invite?
    first_user?
  end

  # Send a push notification to all of this user's devices
  def send_push_notification(title:, message:, path: nil, icon: nil)
    return if push_subscriptions.empty?

    push_subscriptions.each do |subscription|
      WebPushJob.perform_later(
        title: title,
        message: message,
        endpoint: subscription.endpoint,
        p256dh_key: subscription.p256dh_key,
        auth_key: subscription.auth_key,
        path: path,
        icon: icon
      )
    end
  end
end
