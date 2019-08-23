class WebauthnCredential < ApplicationRecord
  validates :external_id, :public_key, :nickname, presence: true
  belongs_to :user
end
