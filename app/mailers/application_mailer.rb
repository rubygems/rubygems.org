class ApplicationMailer < ActionMailer::Base
  include SemanticLogger::Loggable

  layout "mailer"

  after_deliver :record_delivery

  def record_delivery
    message.to_addrs&.each do |address|
      next unless (user = User.find_by_email(address))

      user.record_event!(Events::UserEvent::EMAIL_SENT,
        to: address,
        from: message.from_addrs&.first,
        subject: message.subject,
        message_id: message.message_id,
        action: action_name,
        mailer: mailer_name)
    end
  end
end
