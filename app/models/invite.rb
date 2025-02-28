class Invite < ApplicationRecord
  belongs_to :user

  before_create :set_token

  scope :active, -> { where(used: false) }

  # The mark_as_used! method has been removed
  # as invites can now be used multiple times

  def invalidate!
    update(used: true)
  end

  def regenerate!
    update(token: SecureRandom.urlsafe_base64(32),
           used: false)
  end

  # Find or create a valid invite for a user
  def self.get_active_for(user)
    active_invite = user.invites.active.first

    if active_invite
      active_invite
    else
      new_invite = user.invites.create
      new_invite
    end
  end

  private

  def set_token
    self.token = SecureRandom.urlsafe_base64(32)
  end
end
