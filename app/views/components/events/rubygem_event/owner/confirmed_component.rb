# frozen_string_literal: true

class Events::RubygemEvent::Owner::ConfirmedComponent < Events::TableDetailsComponent
  def template
    div { t(".owner_added_owner_html", owner: link_to_user_from_gid(additional["owner_gid"], additional["owner"])) }
    return unless (authorizer = additional["authorizer"].presence)
    div { t(".owner_added_authorizer_html", authorizer:) }
  end
end
