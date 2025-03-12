class Invite < ApplicationRecord
  belongs_to :user

  before_create :set_token

  def regenerate!
    update(token: SecureRandom.urlsafe_base64(32))
  end

  private

  def set_token
    self.token = SecureRandom.urlsafe_base64(32)
  end
end
