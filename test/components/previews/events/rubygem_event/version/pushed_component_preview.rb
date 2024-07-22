class Events::RubygemEvent::Version::PushedComponentPreview < Lookbook::Preview
  def default(rubygem: Rubygem.first!, # rubocop:disable Metrics/ParameterLists
    number: "1.0.0", platform: "ruby",
    version_gid: rubygem.versions.where(number:, platform:).first&.to_gid,
    pushed_by: "Pusher", actor_gid: version_gid&.find&.pusher&.to_gid)
    event = FactoryBot.build(:events_rubygem_event, rubygem:, tag: Events::RubygemEvent::VERSION_PUSHED, additional:
    {
      number:,
      platform:,
      pushed_by:,

      version_gid:,
      actor_gid:
    })
    render Events::RubygemEvent::Version::PushedComponent.new(
      event:
    )
  end
end
