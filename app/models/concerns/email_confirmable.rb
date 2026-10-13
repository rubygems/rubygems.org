# frozen_string_literal: true

module EmailConfirmable
  extend ActiveSupport::Concern

  class_methods do
    def find_by_email_confirmation_token(token)
      return if token.blank?

      find_by(email_confirmation_token_digest: email_confirmation_token_digest(token))
    end

    def email_confirmation_token_digest(token)
      OpenSSL::Digest::SHA256.hexdigest(token)
    end
  end

  def issue_email_confirmation!(target_email)
    with_lock do
      return unless target_email == email_confirmation_target

      token = SecureRandom.hex(24)
      expires_after = email_confirmed? ? Gemcutter::EMAIL_CHANGE_CONFIRMATION_TOKEN_EXPIRES_AFTER : Gemcutter::SIGN_UP_CONFIRMATION_TOKEN_EXPIRES_AFTER
      update_columns(
        email_confirmation_token_digest: self.class.email_confirmation_token_digest(token),
        email_confirmation_token_expires_at: expires_after.from_now,
        email_confirmation_email: target_email,
        confirmation_token: nil,
        token_expires_at: nil
      )
      token
    end
  end

  def invalidate_email_confirmation!
    update_columns(cleared_email_confirmation_attributes)
  end

  def valid_email_confirmation_token?(token)
    return false if token.blank? || email_confirmation_token_digest.blank? || email_confirmation_token_expires_at.blank?
    return false unless email_confirmation_email == email_confirmation_target

    ActiveSupport::SecurityUtils.secure_compare(
      email_confirmation_token_digest,
      self.class.email_confirmation_token_digest(token)
    ) && Time.current.before?(email_confirmation_token_expires_at)
  end

  def confirm_email_with_token(token)
    with_lock do
      return :invalid_token unless valid_email_confirmation_token?(token)

      target_email = email_confirmation_email
      changing_email = email_confirmed?
      self.email = target_email if changing_email
      self.mail_fails = 0 if changing_email
      self.email_confirmed = true
      self.unconfirmed_email = nil
      clear_email_confirmation
      return :invalid_email unless save

      # Email changes record this event in User's after_update callback.
      record_event!(Events::UserEvent::EMAIL_VERIFIED, email:) unless changing_email
      :confirmed
    end
  end

  private

  def email_confirmation_target
    email_confirmed? ? unconfirmed_email : email
  end

  def clear_email_confirmation
    assign_attributes(cleared_email_confirmation_attributes)
  end

  def cleared_email_confirmation_attributes
    {
      email_confirmation_token_digest: nil,
      email_confirmation_token_expires_at: nil,
      email_confirmation_email: nil,
      confirmation_token: nil,
      token_expires_at: nil
    }
  end
end
