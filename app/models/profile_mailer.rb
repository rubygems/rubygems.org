class ProfileMailer < ActionMailer::Base

  default_url_options[:host] = HOST
  
  def email_reset(user)
    from        DO_NOT_REPLY
    recipients  user.email  
    subject     'Confirm your email address'
    body        :user => user
  end
  
end
