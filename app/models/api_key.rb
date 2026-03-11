class ApiKey < ApplicationRecord
  belongs_to :user

  before_validation :generate_key, on: :create

  validates :name, presence: true, length: { maximum: 255 }
  validates :key, presence: true, uniqueness: true

  def regenerate_key!
    generate_key
    save!
  end

  private

  def generate_key
    self.key = SecureRandom.hex(32)
  end
end
