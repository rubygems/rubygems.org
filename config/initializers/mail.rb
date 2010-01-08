ActionMailer::Base.smtp_settings = {
  :address => "smtp.gmail.com",
  :port => "587",
  :domain => ENV['MAIL_DOMAIN'],
  :authentication => :plain,
  :user_name => ENV['MAIL_USERNAME'],
  :password => ENV['MAIL_PASSWORD']
}

DO_NOT_REPLY = "donotreply@gemcutter.org"
