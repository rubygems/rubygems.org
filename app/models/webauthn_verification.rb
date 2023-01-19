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
end
