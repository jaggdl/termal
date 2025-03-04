# Configure Web Push notifications
Rails.application.config.to_prepare do
  # Load VAPID keys from credentials
  vapid_public_key = Rails.application.credentials.dig(:vapid, :public_key)
  vapid_private_key = Rails.application.credentials.dig(:vapid, :private_key)
  vapid_contact_email = Rails.application.credentials.dig(:vapid, :contact_email)

  # If VAPID keys aren't in credentials, check for environment variables
  vapid_public_key ||= ENV["VAPID_PUBLIC_KEY"]
  vapid_private_key ||= ENV["VAPID_PRIVATE_KEY"]
  vapid_contact_email ||= ENV["VAPID_CONTACT_EMAIL"] || "noreply@example.com"

  if vapid_public_key.present? && vapid_private_key.present?
    # Store VAPID keys in application config
    Rails.configuration.x.vapid = {
      public_key: vapid_public_key,
      private_key: vapid_private_key,
      contact_email: vapid_contact_email
    }

    Rails.logger.info "VAPID keys configured for web push notifications"
  else
    Rails.logger.warn "VAPID keys not found. Web push notifications will not work. Generate keys and add them to credentials or environment variables."
  end
end
