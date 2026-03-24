class Current < ActiveSupport::CurrentAttributes
  attribute :session, :latitude, :longitude
  delegate :user, to: :session, allow_nil: true
  delegate :user_profile, to: :user, allow_nil: true
  delegate :user_meals, to: :user, allow_nil: true
end
