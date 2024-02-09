# frozen_string_literal: true

class Events::UserEvent::Email::SentComponent < Events::TableDetailsComponent
  def template
    plain t(".email_sent_subject", subject: additional.subject)
    br
    plain t(".email_sent_from", from: additional.from)
    br
    plain t(".email_sent_to", to: additional.to)
  end
end
