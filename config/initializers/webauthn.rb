WebAuthn.configure do |config|
  config.origin = if Rails.env.development? || Rails.env.test?
                    ENV.fetch("WEBAUTHN_ORIGIN", "http://localhost:3000")
                  else
                    "#{Rails.application.config.rubygems.protocol}://#{Rails.application.config.rubygems.host}"
                  end
  config.rp_name = "RubyGems.org"
end
