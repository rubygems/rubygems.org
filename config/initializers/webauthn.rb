WebAuthn.configure do |config|
  config.origin = if Rails.env.development?
                    ENV.fetch("WEBAUTHN_ORIGIN", "http://localhost:3000")
                  elsif Rails.env.test?
                    "#{Gemcutter::PROTOCOL}://#{Gemcutter::HOST}:31337"
                  else
                    "#{Gemcutter::PROTOCOL}://#{Gemcutter::HOST}"
                  end
  config.rp_name = Gemcutter::HOST_DISPLAY
  # config.rp_id = Gemcutter::HOST
end
