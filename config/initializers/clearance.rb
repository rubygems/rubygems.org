Clearance.configure do |config|
  config.allow_sign_up = (ENV['DISABLE_SIGNUP'].to_s == 'true') ? false : true
  config.mailer_sender = "RubyGems.org <no-reply@mailer.rubygems.org>"
  config.secure_cookie = true unless Rails.env.test? || Rails.env.development?
  config.password_strategy = Clearance::PasswordStrategies::BCryptMigrationFromSHA1
  config.sign_in_guards = [ConfirmedUserGuard]
end
