module ApiAuthentication
  extend ActiveSupport::Concern

  included do
    allow_unauthenticated_access
    before_action :authenticate_api_key
  end

  private

  def authenticate_api_key
    api_key = extract_api_key

    if api_key.blank?
      render json: { error: "API key is missing" }, status: :unauthorized
      return
    end

    @api_key = ApiKey.find_by(key: api_key)

    if @api_key.nil?
      render json: { error: "Invalid API key" }, status: :unauthorized
      return
    end

    Current.session = @api_key

    @api_key.touch(:last_used_at)
  end

  def extract_api_key
    auth_header = request.headers["Authorization"]

    if auth_header.present? && auth_header.start_with?("Bearer ")
      auth_header.sub("Bearer ", "")
    end
  end
end
