class WebauthnCredential < ApplicationRecord
  belongs_to :user

  validates :external_id, uniqueness: true, presence: true
  validates :public_key, presence: true
  validates :nickname, presence: true, uniqueness: { scope: :user_id }
  validates :sign_count, presence: true, numericality: { greater_than_or_equal_to: 0 }

  after_create :send_creation_email
  after_destroy :send_deletion_email

  private

  def send_creation_email
    Mailer.webauthn_credential_created(id).deliver_later
  end

  def send_deletion_email
    Mailer.webauthn_credential_removed(user_id, nickname, Time.now.utc).deliver_later
  end
end
