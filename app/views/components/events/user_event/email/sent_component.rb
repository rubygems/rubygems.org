# frozen_string_literal: true

class Events::UserEvent::Email::SentComponent < Events::TableDetailsComponent
  def template
    t(".email_sent_subject", subject: event.additional["subject"])
    br
    t(".email_sent_from", from: event.additional["from"])
    br
    t(".email_sent_to", to: event.additional["to"])
  end
end
