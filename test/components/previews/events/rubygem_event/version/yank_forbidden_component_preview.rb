class Events::RubygemEvent::Version::YankForbiddenComponentPreview < Lookbook::Preview
  def default(rubygem: Rubygem.first!, # rubocop:disable Metrics/ParameterLists
    reason: "Versions used for testing can't be yanked.",
    number: "0.0.1", platform: "ruby",
    version_gid: rubygem.versions.where(number:, platform:).first&.to_gid,
    yanked_by: "Yanker", actor_gid: version_gid&.find&.yanker&.to_gid)
    event = FactoryBot.build(:events_rubygem_event, rubygem:, tag: Events::RubygemEvent::VERSION_YANK_FORBIDDEN, additional:
    {
      number:,
      platform:,
      yanked_by:,

      version_gid:,
      actor_gid:,
      reason:
    })
    render Events::RubygemEvent::Version::YankForbiddenComponent.new(
      event:
    )
  end
end
