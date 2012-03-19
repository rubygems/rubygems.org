# Be sure to restart your server when you modify this file.

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.

if Rails.env.maintenance? || Rails.env.staging? || Rails.env.production?
  secret_path = Rails.root.join("config", "secret.rb")
  if secret_path.file?
    require secret_path.to_s
  end
end

Rails.application.config.secret_token = ENV['SECRET_TOKEN'] || '53336f5ffda880aa2f6d5fbb7603b6df4d975408afbf44642d342547c25f92265eb01c34b118ee7fa87475f69949b07b292d95276aae2f6bda029ea25d28dc28'
