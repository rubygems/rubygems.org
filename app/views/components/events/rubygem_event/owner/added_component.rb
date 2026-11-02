# frozen_string_literal: true

class Events::RubygemEvent::Owner::AddedComponent < Events::TableDetailsComponent
  def view_template
    raw t(".owner_added_owner_html", owner: link_to_user_from_gid(additional.owner_gid, additional.owner))
    authorizer = additional.authorizer.presence
    return unless authorizer
    br
    raw t(".owner_added_authorizer_html", authorizer: link_to_user_from_gid(additional.actor_gid, authorizer))
  end
end
