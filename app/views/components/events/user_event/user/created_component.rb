# frozen_string_literal: true

class Events::UserEvent::User::CreatedComponent < Events::TableDetailsComponent
  def template
    plain t(".email", email: additional.email)
  end
end
