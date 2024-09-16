unless Rails.env.local?
  ActionMailer::Base.smtp_settings = {
    address:              'smtp.sendgrid.net',
    port:                 587,
    user_name:            ENV['SENDGRID_USERNAME'],
    password:             ENV['SENDGRID_PASSWORD'],
    domain:               'mailer.rubygems.org',
    authentication:       :plain,
    enable_starttls:      true
  }
  ActionMailer::Base.delivery_method = :smtp
end
