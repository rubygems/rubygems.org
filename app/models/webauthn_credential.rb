class WebauthnCredential < ApplicationRecord
  belongs_to :user

  validates :external_id, uniqueness: true, presence: true
  validates :public_key, presence: true
  validates :nickname, presence: true, uniqueness: { scope: :user_id }
  validates :sign_count, presence: true, numericality: { greater_than_or_equal_to: 0 }

  after_create :send_creation_email
  after_create :enable_user_mfa
  after_destroy :send_deletion_email
  after_destroy :disable_user_mfa

  private

  def send_creation_email
    Mailer.webauthn_credential_created(id).deliver_later
  end

  def send_deletion_email
    Mailer.webauthn_credential_removed(user_id, nickname, Time.now.utc).deliver_later
  end

  def enable_user_mfa
    return unless user.mfa_device_count_one?
    user.mfa_level = :ui_and_api
    user.mfa_recovery_codes = Array.new(10).map { SecureRandom.hex(6) }
    user.mfa_hashed_recovery_codes = user.mfa_recovery_codes.map { |code| BCrypt::Password.create(code) }
    user.save!(validate: false)
  end

  def disable_user_mfa
    return unless user.no_mfa_devices?
    user.mfa_level = :disabled
    user.mfa_recovery_codes = []
    user.mfa_hashed_recovery_codes = []
    user.save!(validate: false)
  end
end
