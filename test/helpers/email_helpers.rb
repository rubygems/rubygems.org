module EmailHelpers
  def last_email_link
    Delayed::Worker.new.work_off
    body = last_email.body.decoded.to_s
    link = %r{http://localhost/email_confirmations([^";]*)}.match(body)
    link[0]
  end

  def last_email
    ActionMailer::Base.deliveries.last
  end

  def mails_count
    ActionMailer::Base.deliveries.size
  end
end
