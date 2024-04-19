# frozen_string_literal: true

class Events::RubygemEvent::Version::YankForbiddenComponent < Events::TableDetailsComponent
  def template
    div do
      t(".version_html", version:
        link_to_version_from_gid(additional.version_gid, additional.number, additional.platform))
    end
    return if additional.yanked_by.blank?
    div do
      t(".version_yanked_by_html", pusher: link_to_user_from_gid(additional.actor_gid, additional.yanked_by))
    end
  end
end
