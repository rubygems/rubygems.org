Clearance.configure do |config|
  config.mailer_sender = "help@rubygems.org"
  config.secure_cookie = true unless Rails.env.test? || Rails.env.development?
  config.password_strategy = Clearance::PasswordStrategies::BCryptMigrationFromSHA1
end
