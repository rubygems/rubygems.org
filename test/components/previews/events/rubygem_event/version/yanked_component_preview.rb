class Events::RubygemEvent::Version::YankedComponentPreview < Lookbook::Preview
  def default(rubygem: Rubygem.first!, **additional)
    additional[:number] ||= "0.0.1"
    additional[:platform] ||= "ruby"
    version = rubygem.versions.find_by(additional.slice(:number, :platform))
    additional[:version_gid] ||= version&.to_gid
    additional[:actor_gid] ||= version&.yanker&.to_gid
    additional[:yanked_by] ||= "Yanker"

    event = FactoryBot.build(:events_rubygem_event, rubygem:, tag: Events::RubygemEvent::VERSION_YANKED, additional:)
    render Events::RubygemEvent::Version::YankedComponent.new(event:)
  end
end
