class Events::RubygemEvent::Version::PushedComponentPreview < Lookbook::Preview
  def default(rubygem: Rubygem.first!, **additional)
    additional[:number] ||= "1.0.0"
    additional[:platform] ||= "ruby"
    version = rubygem.versions.find_by(additional.slice(:number, :platform))
    additional[:version_gid] ||= version&.to_gid
    additional[:actor_gid] ||= version&.pusher&.to_gid
    additional[:pushed_by] ||= "Pusher"

    event = FactoryBot.build(:events_rubygem_event, rubygem:, tag: Events::RubygemEvent::VERSION_PUSHED, additional:)
    render Events::RubygemEvent::Version::PushedComponent.new(event:)
  end
end
