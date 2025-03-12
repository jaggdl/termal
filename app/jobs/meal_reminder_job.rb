class MealReminderJob < ApplicationJob
  queue_as :default

  def perform
    User.joins(:push_subscriptions).distinct.find_each do |user|
      next unless user.user_profile

      today = user.user_today
      has_meals_today = user.user_meals_on_date(today).exists?

      unless has_meals_today
        user.send_push_notification(
          title: "Meal Reminder",
          message: "Don't forget to log your meals for today!",
          path: "/",
          icon: "/icon.png"
        )
      end
    end
  end
end
