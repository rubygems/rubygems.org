unless Rails.env.maintenance?
  Clearance.configure do |config|
    config.mailer_sender = "donotreply@rubygems.org"
    config.secure_cookie = true
  end
end
