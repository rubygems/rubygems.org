class Events::RubygemEvent::Owner::ConfirmedComponentPreview < Lookbook::Preview
  # @param owner text
  def default(owner: "Owner", user: User.first!)
    event = FactoryBot.build(:events_rubygem_event, tag: Events::RubygemEvent::OWNER_CONFIRMED, additional:
    {
      owner:,
      owner_gid: user.to_gid.to_s,
      actor_gid: user.to_gid.to_s
    })
    render Events::RubygemEvent::Owner::ConfirmedComponent.new(
      event:
    )
  end
end
