Rails.application.config.after_initialize do
  Rails.application.config.secret_token = ENV['SECRET_TOKEN'] || "deadbeef" * 10

  if Rails.env.test?
    Rails.application.config.secret_key_base =  "deadbeef" * 10
  else
    Rails.application.config.secret_key_base = ENV['SECRET_KEY_BASE']
  end
end
