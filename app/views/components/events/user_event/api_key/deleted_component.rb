# frozen_string_literal: true

class Events::UserEvent::ApiKey::DeletedComponent < Events::TableDetailsComponent
  def view_template
    plain t(".api_key_name", name: event.additional.name)
  end
end
