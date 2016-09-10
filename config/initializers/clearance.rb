Clearance.configure do |config|
  config.allow_sign_up = (ENV['DISABLE_SIGNUP'].to_s == 'true') ? false : true
  config.mailer_sender = "help@rubygems.org"
  config.secure_cookie = true unless Rails.env.test? || Rails.env.development?
  config.password_strategy = Clearance::PasswordStrategies::BCryptMigrationFromSHA1
end
