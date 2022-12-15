class WebauthnVerification < ApplicationRecord
  belongs_to :user

  validates :user_id, uniqueness: true
  validates :path_token, presence: true, uniqueness: true
  validates :path_token_expires_at, presence: true
end
