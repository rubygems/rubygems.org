WebAuthn.configure do |config|
  config.allowed_origins = [if Rails.env.development?
                              ENV.fetch("WEBAUTHN_ORIGIN", "http://localhost:3000")
                            else
                              "#{Gemcutter::PROTOCOL}://#{Gemcutter::HOST}"
                            end]
  config.rp_name = Gemcutter::HOST_DISPLAY
  # config.rp_id = Gemcutter::HOST
end
