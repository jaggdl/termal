class MealReminderJob < ApplicationJob
  queue_as :default

  def perform
    User.joins(:push_subscriptions).distinct.find_each do |user|
      user.send_push_notification(
        title: "Meal Reminder",
        message: "Don't forget to log your meals for today!",
        path: "/user_meals/new",
        icon: "/icon.png"
      )
    end
  end
end
