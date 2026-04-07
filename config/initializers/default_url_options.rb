# frozen_string_literal: true

Rails.application.routes.default_url_options = {
  host: ENV.fetch("BASE_URL", "https://your-instance.com").gsub(%r{^https?://}, ""),
  protocol: ENV.fetch("BASE_URL", "https://").match?(%r{^https://}) ? "https" : "http"
}
