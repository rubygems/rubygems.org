class Events::RubygemEvent::Owner::RemovedComponentPreview < Lookbook::Preview
  # @param owner text
  def default(owner: "Owner", user: User.first!)
    event = FactoryBot.build(:events_rubygem_event, tag: Events::RubygemEvent::OWNER_REMOVED, additional:
    {
      owner:,
      owner_gid: user.to_gid.to_s,
      actor_gid: user.to_gid.to_s
    })
    render Events::RubygemEvent::Owner::RemovedComponent.new(
      event:
    )
  end
end
