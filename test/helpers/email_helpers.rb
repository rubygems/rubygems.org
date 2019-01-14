module EmailHelpers
  def last_email_link
    Delayed::Worker.new.work_off
    body = ActionMailer::Base.deliveries.last.body.decoded.to_s
    link = %r{http://localhost/email_confirmations([^";]*)}.match(body)
    link[0]
  end
end
