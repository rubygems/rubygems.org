module EmailHelpers
  def last_email
    Delayed::Worker.new.work_off
    ActionMailer::Base.deliveries.last
  end

  def last_email_link
    body = last_email.body.decoded.to_s
    link = %r{http://localhost/email_confirmations([^";]*)}.match(body)
    link[0]
  end
end
