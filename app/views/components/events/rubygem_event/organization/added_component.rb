# frozen_string_literal: true

class Events::RubygemEvent::Organization::AddedComponent < Events::TableDetailsComponent
  def view_template
    div do
      t(".organization_added_organization_html", organization: link_to_organization_from_gid)
    end
    return if additional.added_by.blank?
    div do
      t(".organization_added_by_html", user: link_to_user_from_gid(additional.actor_gid, additional.added_by))
    end
  end

  private

  def link_to_organization_from_gid
    organization = load_gid(additional.organization_gid, only: ::Organization)
    return additional.organization unless organization

    view_context.link_to organization.handle, organization_path(organization.handle)
  end
end
