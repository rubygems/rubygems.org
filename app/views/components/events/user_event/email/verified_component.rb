# frozen_string_literal: true

class Events::UserEvent::Email::VerifiedComponent < Events::TableDetailsComponent
  def view_template
    email = additional.email
    return if email.blank?
    code { plain email }
  end
end
