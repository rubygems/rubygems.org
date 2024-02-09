class Events::RubygemEvent::Version::YankedComponentPreview < Lookbook::Preview
  def default(rubygem: Rubygem.first!, # rubocop:disable Metrics/ParameterLists
    number: "0.0.1", platform: "ruby",
    version_gid: rubygem.versions.where(number:, platform:).first&.to_gid,
    yanked_by: "Yanker", actor_gid: version_gid&.find&.yanker&.to_gid)
    event = FactoryBot.build(:events_rubygem_event, rubygem:, tag: Events::RubygemEvent::VERSION_YANKED, additional:
    {
      number:,
      platform:,
      yanked_by:,

      version_gid:,
      actor_gid:
    })
    render Events::RubygemEvent::Version::YankedComponent.new(
      event:
    )
  end
end
