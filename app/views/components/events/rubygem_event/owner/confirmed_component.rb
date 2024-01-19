# frozen_string_literal: true

class Events::RubygemEvent::Owner::ConfirmedComponent < Events::TableDetailsComponent
  def template
    div { t(".owner_added_owner_html", owner: link_to_user_from_gid(event.additional["owner_gid"], event.additional["owner"])) }
    return unless (authorizer = event.additional["authorizer"].presence)
    div { t(".owner_added_authorizer_html", authorizer:) }
  end
end
