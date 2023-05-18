module UserWebauthnMethods
  extend ActiveSupport::Concern

  included do
    has_many :webauthn_credentials, dependent: :destroy
    has_one :webauthn_verification, dependent: :destroy

    after_initialize do
      self.webauthn_id ||= WebAuthn.generate_user_id
    end
  end

  def webauthn_options_for_create
    WebAuthn::Credential.options_for_create(
      user: {
        id: webauthn_id,
        name: display_id
      },
      exclude: webauthn_credentials.pluck(:external_id),
      authenticator_selection: { user_verification: "discouraged" }
    )
  end

  def webauthn_options_for_get
    WebAuthn::Credential.options_for_get(
      allow: webauthn_credentials.pluck(:external_id),
      user_verification: "discouraged"
    )
  end

  def refresh_webauthn_verification
    self.webauthn_verification = WebauthnVerification.create(
      path_token: SecureRandom.base58(16),
      path_token_expires_at: 2.minutes.from_now,
      user_id: id
    )
  end

  private

  def verify_webauthn_otp(otp)
    webauthn_verification&.verify_otp(otp)
  end
end
