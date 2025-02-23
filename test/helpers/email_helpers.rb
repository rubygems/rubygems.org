module EmailHelpers
  def last_email_link
    perform_enqueued_jobs only: ActionMailer::MailDeliveryJob
    confirmation_link
  end

  def last_email
    ActionMailer::Base.deliveries.last
  end

  def mails_count
    ActionMailer::Base.deliveries.size
  end

  def confirmation_link
    refute_empty ActionMailer::Base.deliveries
    body = last_email.parts[1].body.decoded.to_s
    link = %r{http://localhost(?::\d+)?/email_confirmations([^";]*)}.match(body)
    URI.parse(link[0]).request_uri
  end
end
