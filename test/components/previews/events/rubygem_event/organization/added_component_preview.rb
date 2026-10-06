# frozen_string_literal: true

class Events::RubygemEvent::Organization::AddedComponentPreview < Lookbook::Preview
  def default(rubygem: Rubygem.first!, organization: Organization.first!, user: User.first!)
    event = FactoryBot.build(:events_rubygem_event, rubygem:, tag: Events::RubygemEvent::ORGANIZATION_ADDED, additional: {
                               organization: organization.handle, organization_gid: organization.to_gid,
      added_by: user.display_handle, actor_gid: user.to_gid
                             })
    render Events::RubygemEvent::Organization::AddedComponent.new(event:)
  end
end
