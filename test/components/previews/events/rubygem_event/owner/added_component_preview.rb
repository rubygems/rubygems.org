class Events::RubygemEvent::Owner::AddedComponentPreview < Lookbook::Preview
  # @param owner text
  # @param authorizer text
  def default(owner: "Owner", authorizer: "Authorizer", user: User.first!)
    event = FactoryBot.build(:events_rubygem_event, tag: Events::RubygemEvent::OWNER_ADDED, additional:
    {
      owner:,
      owner_gid: user.to_gid.to_s,
      authorizer:,
      actor_gid: user.to_gid.to_s
    })
    render Events::RubygemEvent::Owner::AddedComponent.new(event:)
  end

  # @param owner text
  # @param authorizer text
  def without_actor(owner: "Owner", authorizer: "Authorizer", user: User.first!)
    event = FactoryBot.build(:events_rubygem_event,
    tag: Events::RubygemEvent::OWNER_ADDED,
    additional:
    {
      owner:,
      owner_gid: user.to_gid.to_s,
      authorizer:
    })
    render Events::RubygemEvent::Owner::AddedComponent.new(event:)
  end

  # @param owner text
  def without_authorizer(owner: "Owner", user: User.first!)
    event = FactoryBot.build(:events_rubygem_event, tag: Events::RubygemEvent::OWNER_ADDED, additional:
    {
      owner:,
      owner_gid: user.to_gid.to_s,
      actor_gid: user.to_gid.to_s
    })
    render Events::RubygemEvent::Owner::AddedComponent.new(event:)
  end
end
