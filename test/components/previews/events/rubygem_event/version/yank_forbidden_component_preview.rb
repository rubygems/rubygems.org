class Events::RubygemEvent::Version::YankForbiddenComponentPreview < Lookbook::Preview
  def default(rubygem: Rubygem.first!, **additional)
    additional[:reason] ||= "Versions used for testing can't be yanked."
    additional[:number] ||= "0.0.1"
    additional[:platform] ||= "ruby"
    version = rubygem.versions.find_by(additional.slice(:number, :platform))
    additional[:version_gid] ||= version&.to_gid
    additional[:actor_gid] ||= version&.yanker&.to_gid
    additional[:yanked_by] ||= "Yanker"

    event = FactoryBot.build(:events_rubygem_event, rubygem:, tag: Events::RubygemEvent::VERSION_YANK_FORBIDDEN, additional:)
    render Events::RubygemEvent::Version::YankForbiddenComponent.new(event:)
  end
end
