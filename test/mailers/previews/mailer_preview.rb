class MailerPreview < ActionMailer::Preview
  def email_reset
    Mailer.email_reset(User.last)
  end

  def email_confirmation
    Mailer.email_confirmation(User.last)
  end

  def change_password
    ClearanceMailer.change_password(User.last)
  end

  def deletion_complete
    Mailer.deletion_complete(User.last)
  end

  def deletion_failed
    Mailer.deletion_failed(User.last)
  end
end
