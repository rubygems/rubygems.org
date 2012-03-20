Rails.application.config.after_initialize do
  Rails.application.config.secret_token = ENV['SECRET_TOKEN'] || "deadbeef" * 10
end
