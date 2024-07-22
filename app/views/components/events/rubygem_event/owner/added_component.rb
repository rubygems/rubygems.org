# frozen_string_literal: true

class Events::RubygemEvent::Owner::AddedComponent < Events::TableDetailsComponent
  def view_template
    plain t(".owner_added_owner_html", owner: link_to_user_from_gid(additional.owner_gid, additional.owner))
    return unless (authorizer = additional.authorizer.presence)
    br
    plain t(".owner_added_authorizer_html", authorizer: link_to_user_from_gid(additional.actor_gid, authorizer))
  end
end
