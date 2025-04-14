# frozen_string_literal: true

class Rails::PwaController < ApplicationController
  allow_unauthenticated_access
  skip_forgery_protection

  def service_worker
    # Set appropriate content type and cache headers
    response.headers["Content-Type"] = "application/javascript"
    response.headers["Service-Worker-Allowed"] = "/"
    response.headers["Cache-Control"] = "max-age=0"

    render template: "pwa/service-worker", layout: false
  end

  def manifest
    # Set the content type to JSON and disable caching to ensure theme changes are reflected
    response.headers["Content-Type"] = "application/json"
    response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"

    render template: "pwa/manifest", layout: false
  end
end
