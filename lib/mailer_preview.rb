class MailerPreview < ActionMailer::Preview
  def email_reset
    Mailer.email_reset(User.last)
  end

  def email_confirmation
    Mailer.email_confirmation(User.last)
  end
end
