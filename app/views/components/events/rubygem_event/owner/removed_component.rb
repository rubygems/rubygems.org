# frozen_string_literal: true

class Events::RubygemEvent::Owner::RemovedComponent < Events::TableDetailsComponent
  def view_template
    plain t(".owner_removed_owner_html", owner: link_to_user_from_gid(additional["owner_gid"], additional["owner"]))
    remover = additional["removed_by"].presence
    return unless remover
    br
    plain t(".owner_removed_by_html", remover: link_to_user_from_gid(additional["actor_gid"], remover))
  end
end
