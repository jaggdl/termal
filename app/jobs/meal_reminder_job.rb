class MealReminderJob < ApplicationJob
  queue_as :default

  def perform
    User.joins(:push_subscriptions).distinct.find_each do |user|
      user.push_subscriptions.each do |subscription|
        WebPushJob.perform_later(
          title: "Meal Reminder",
          message: "Don't forget to log your meals for today!",
          endpoint: subscription.endpoint,
          p256dh_key: subscription.p256dh_key,
          auth_key: subscription.auth_key,
          path: "/user_meals/new",
          icon: "/icon.png"
        )
      end
    end
  end
end
