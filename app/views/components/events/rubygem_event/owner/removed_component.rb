# frozen_string_literal: true

class Events::RubygemEvent::Owner::RemovedComponent < Events::TableDetailsComponent
  def view_template
    div { t(".owner_removed_owner_html", owner: link_to_user_from_gid(additional["owner_gid"], additional["owner"])) }
    return unless (remover = additional["removed_by"].presence)
    div { t(".owner_removed_by_html", remover: link_to_user_from_gid(additional["actor_gid"], remover)) }
  end
end
