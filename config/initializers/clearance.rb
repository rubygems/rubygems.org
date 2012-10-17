unless Rails.env.maintenance?
  Clearance.configure do |config|
    config.mailer_sender = "donotreply@rubygems.org"
  end
end
