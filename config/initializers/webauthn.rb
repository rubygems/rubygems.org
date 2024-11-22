WebAuthn.configure do |config|
  config.origin = if Rails.env.development?
                    ENV.fetch("WEBAUTHN_ORIGIN", "http://localhost:3000")
                  elsif Rails.env.test?
                    if ENV["DEVCONTAINER_APP_HOST"].present?
                      "#{ENV['DEVCONTAINER_APP_HOST']}:#{ENV['CAPYBARA_SERVER_PORT']}"
                    else
                      "#{Gemcutter::PROTOCOL}://#{Gemcutter::HOST}:31337"
                    end
                  else
                    "#{Gemcutter::PROTOCOL}://#{Gemcutter::HOST}"
                  end
  config.rp_name = Gemcutter::HOST_DISPLAY
  # config.rp_id = Gemcutter::HOST
end
