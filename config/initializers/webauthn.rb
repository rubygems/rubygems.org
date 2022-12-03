WebAuthn.configure do |config|
  config.origin = if Rails.env.staging? || Rails.env.production?
                    "#{Rails.application.config.rubygems.protocol}://#{Rails.application.config.rubygems.host}"
                  else
                    ENV.fetch("WEBAUTHN_ORIGIN", "http://localhost:3000")
                  end
  config.rp_name = "RubyGems.org"
end
