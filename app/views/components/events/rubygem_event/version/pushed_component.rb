class Events::RubygemEvent::Version::PushedComponent < Events::TableDetailsComponent
  delegate :rubygem, to: :event

  def view_template
    div do
      t(".version_html", version:
        link_to_version_from_gid(additional.version_gid, additional.number, additional.platform))
    end
    if additional.sha256.present?
      sha256 = capture { code(class: "tw-break-all") { additional.sha256 } }
      div { t(".version_pushed_sha256_html", sha256:) }
    end
    return if additional.pushed_by.blank?
    div do
      t(".version_pushed_by_html", pusher: link_to_user_from_gid(additional.actor_gid, additional.pushed_by))
    end
  end
end
