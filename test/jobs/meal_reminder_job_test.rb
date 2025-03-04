require "test_helper"

class MealReminderJobTest < ActiveJob::TestCase
  test "sends push notifications to all users with subscriptions" do
    # Create two users with push subscriptions
    user1 = users(:valid)
    user2 = User.create!(email: "test2@example.com", password: "password")

    # Create push subscriptions for both users
    sub1 = PushSubscription.create!(
      user: user1,
      endpoint: "https://example.com/endpoint1",
      p256dh_key: "key1",
      auth_key: "auth1"
    )

    sub2 = PushSubscription.create!(
      user: user2,
      endpoint: "https://example.com/endpoint2",
      p256dh_key: "key2",
      auth_key: "auth2"
    )

    # Track number of jobs enqueued
    assert_enqueued_jobs 2, only: WebPushJob do
      MealReminderJob.perform_now
    end
  end
end
