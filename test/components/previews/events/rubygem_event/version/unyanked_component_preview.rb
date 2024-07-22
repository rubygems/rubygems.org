class Events::RubygemEvent::Version::UnyankedComponentPreview < Lookbook::Preview
  # @param number text
  # @param platform text
  def default(rubygem: Rubygem.first!, number: "1.0.0", platform: "ruby", version_gid: rubygem.versions.where(number:, platform:).first&.to_gid)
    event = FactoryBot.build(:events_rubygem_event, rubygem:, tag: Events::RubygemEvent::VERSION_UNYANKED, additional:
    {
      number:,
      platform:,

      version_gid:
    })
    render Events::RubygemEvent::Version::UnyankedComponent.new(
      event:
    )
  end

  def without_version_gid(**)
    default(**, version_gid: nil)
  end
end
