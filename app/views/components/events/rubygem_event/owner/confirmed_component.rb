# frozen_string_literal: true

class Events::RubygemEvent::Owner::ConfirmedComponent < Events::TableDetailsComponent
  def view_template
    div { t(".owner_added_owner_html", owner: link_to_user_from_gid(additional["owner_gid"], additional["owner"])) }
    authorizer = additional["authorizer"].presence
    return unless authorizer
    div { t(".owner_added_authorizer_html", authorizer:) }
  end
end
