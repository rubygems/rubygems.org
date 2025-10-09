Rails.application.config.after_initialize do
  Rails.application.config.action_dispatch.cookies_rotations.tap do |cookies|
    salt = Rails.application.config.action_dispatch.authenticated_encrypted_cookie_salt

    # Add rotation for previous secret_key_base (for graceful key rotation without user logout)
    previous_secret_key_base = ENV['PREVIOUS_SECRET_KEY_BASE']
    if previous_secret_key_base.present?
      # Rotate encrypted cookies with old secret
      old_key_generator = Rails.application.key_generator(previous_secret_key_base)
      key_len = ActiveSupport::MessageEncryptor.key_len
      old_secret = old_key_generator.generate_key(salt, key_len)
      cookies.rotate :encrypted, old_secret

      # Rotate session cookies with old secret
      session_salt = Rails.application.config.action_dispatch.signed_cookie_salt
      old_session_secret = old_key_generator.generate_key(session_salt, 64)
      cookies.rotate :signed, old_session_secret
    end
  end
end
