unless Rails.env.maintenance?
  Clearance.configure do |config|
    config.mailer_sender = "donotreply@rubygems.org"
    config.secure_cookie = true
    config.password_strategy = Clearance::PasswordStrategies::BCryptMigrationFromSHA1
  end
end
