require "test_helper"

class MealReminderJobTest < ActiveJob::TestCase
  test "sends push notifications only to users without meals today" do
    # Create two users with push subscriptions
    user1 = users(:valid)
    user2 = User.create!(email: "test2@example.com", password: "password")
    
    # Ensure both users have user profiles for timezone
    user1.create_user_profile!(timezone: "UTC") unless user1.user_profile
    user2.create_user_profile!(timezone: "UTC") unless user2.user_profile
    
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
    
    # Create a meal for user1 for today in their timezone
    today = user1.user_today
    meal = Meal.create!(name: "Test Meal")
    user1.user_meals.create!(
      meal: meal,
      consumed_at: today.in_time_zone(user1.user_profile.timezone).noon
    )
    
    # User1 has a meal today, so only user2 should get a notification
    assert_enqueued_jobs 1, only: WebPushJob do
      MealReminderJob.perform_now
    end
    
    # Verify the notification was for user2
    assert_enqueued_with(
      job: WebPushJob,
      args: [hash_including(endpoint: "https://example.com/endpoint2")]
    )
  end
end
