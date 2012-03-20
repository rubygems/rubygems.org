if Rails.env.maintenance? || Rails.env.staging? || Rails.env.production?
  secret_path = Rails.root.join("config", "secret.rb")
  if secret_path.file?
    require secret_path.to_s
    Rails.application.config.secret_token = ENV['SECRET_TOKEN']
  end
else
  Rails.application.config.secret_token = "deadbeef" * 10
end
