class WebPushJob < ApplicationJob
  queue_as :default

  def perform(title:, message:, endpoint:, p256dh_key:, auth_key:, path: nil, icon: nil)
    message_json = {
      title: title,
      body: message,
      icon: icon || "/icon.png",
      data: {
        path: path || "/"
      }
    }.to_json

    begin
      response = WebPush.payload_send(
        message: message_json,
        endpoint: endpoint,
        p256dh: p256dh_key,
        auth: auth_key,
        vapid: {
          subject: "mailto:#{User.first.email_address}",
          public_key: GlobalSetting.get("vapid_public_key"),
          private_key: GlobalSetting.get("vapid_private_key")
        }
      )

      Rails.logger.info "Push notification sent: #{response.inspect}"
    rescue => e
      Rails.logger.error "Failed to send push notification: #{e.message}"
      raise
    end
  end
end
