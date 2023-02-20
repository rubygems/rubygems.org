Rails.application.config.after_initialize do
  Rails.application.config.action_dispatch.cookies_rotations.tap do |cookies|
    salt = Rails.application.config.action_dispatch.authenticated_encrypted_cookie_salt
    secret_key_base = Rails.application.secret_key_base

    key_generator = ActiveSupport::KeyGenerator.new(
      secret_key_base, iterations: 1000, hash_digest_class: OpenSSL::Digest::SHA1
    )
    key_len = ActiveSupport::MessageEncryptor.key_len
    secret = key_generator.generate_key(salt, key_len)

    cookies.rotate :encrypted, secret
  end
end
