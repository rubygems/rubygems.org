# frozen_string_literal: true

class Events::UserEvent::Email::AddedComponent < Events::TableDetailsComponent
  def template
    code { plain additional.email }
  end
end
