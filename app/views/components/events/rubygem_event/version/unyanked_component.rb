# frozen_string_literal: true

class Events::RubygemEvent::Version::UnyankedComponent < Events::TableDetailsComponent
  def view_template
    plain t(".version_html", version: link_to_version_from_gid(additional.version_gid, additional.number, additional.platform))
  end
end
