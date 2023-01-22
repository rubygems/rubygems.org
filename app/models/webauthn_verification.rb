class WebauthnVerification < ApplicationRecord
  belongs_to :user

  validates :user_id, uniqueness: true
  validates :path_token, presence: true, uniqueness: true
  validates :path_token_expires_at, presence: true

  def expire_path_token
    self.path_token_expires_at = 1.second.ago
    save!
  end

  def path_token_expired?
    path_token_expires_at < Time.now.utc
  end

  def generate_otp
    self.otp = SecureRandom.base58(16)
    self.otp_expires_at = 2.minutes.from_now
    save!
  end

  def verify_otp(otp)
    return false if otp != self.otp || otp_expired?
    expire_otp
  end

  private

  def expire_otp
    self.otp_expires_at = 1.second.ago
    save!
  end

  def otp_expired?
    otp_expires_at < Time.now.utc
  end
end
