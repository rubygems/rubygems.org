module EmailHelpers
  def last_email_link
    Delayed::Worker.new.work_off
    body = ActionMailer::Base.deliveries.last.to_s
    link = /href="([^"]*)"/.match(body)
    link[1]
  end

  def email_confirmation
    Mailer.email_confirmation(User.first)
  end
end
