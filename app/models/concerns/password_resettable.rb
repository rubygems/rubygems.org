# frozen_string_literal: true

module PasswordResettable
  extend ActiveSupport::Concern

  class_methods do
    def find_by_password_reset_token(token)
      return if token.blank?

      find_by(password_reset_token_digest: password_reset_token_digest(token))
    end

    def password_reset_token_digest(token)
      OpenSSL::Digest::SHA256.hexdigest(token)
    end
  end

  def issue_password_reset!
    token = SecureRandom.hex(24)
    update_columns(
      password_reset_token_digest: self.class.password_reset_token_digest(token),
      password_reset_token_expires_at: Gemcutter::EMAIL_TOKEN_EXPIRES_AFTER.from_now,
      confirmation_token: nil,
      token_expires_at: nil,
      unconfirmed_email: nil
    )
    token
  end

  def invalidate_password_reset!
    update_columns(
      password_reset_token_digest: nil,
      password_reset_token_expires_at: nil,
      confirmation_token: nil,
      token_expires_at: nil,
      unconfirmed_email: nil
    )
  end

  def valid_password_reset_token?(token)
    return false if token.blank? || password_reset_token_digest.blank? || password_reset_token_expires_at.blank?

    ActiveSupport::SecurityUtils.secure_compare(
      password_reset_token_digest,
      self.class.password_reset_token_digest(token)
    ) && Time.current.before?(password_reset_token_expires_at)
  end

  def update_password_with_token(new_password, token:)
    with_lock do
      if token.blank? || !valid_password_reset_token?(token)
        :invalid_token
      else
        self.password = new_password
        if valid?
          self.confirmation_token = nil
          self.password_reset_token_digest = nil
          self.password_reset_token_expires_at = nil
          generate_remember_token
          save ? :updated : :invalid_password
        else
          :invalid_password
        end
      end
    end
  end

  def compromised_password_reset_reason_for(token)
    return if token.blank? || password_reset_token_expiry(token).blank?

    Rails.application.message_verifier(:compromised_password_reset).generate(
      token,
      expires_at: password_reset_token_expiry(token)
    )
  end

  def valid_compromised_password_reset_reason?(reason, token:)
    return false unless reason.is_a?(String) && token.present?

    Rails.application.message_verifier(:compromised_password_reset).verified(reason) == token
  end

  private

  def password_reset_token_expiry(token)
    password_reset_token_expires_at if valid_password_reset_token?(token)
  end
end
