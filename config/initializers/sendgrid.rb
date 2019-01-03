# frozen_string_literal: true

if Rails.env.production? || Rails.env.staging?
  ActionMailer::Base.smtp_settings = {
    address:              'smtp.sendgrid.net',
    port:                 587,
    user_name:            ENV['SENDGRID_USERNAME'],
    password:             ENV['SENDGRID_PASSWORD'],
    domain:               'mailer.rubygems.org',
    authentication:       :plain,
    enable_starttls_auto: true
  }
  ActionMailer::Base.delivery_method = :smtp
end
