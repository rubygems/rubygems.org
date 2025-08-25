require "test_helper"

class Events::RubygemEvent::Version::UnyankedComponentTest < ComponentTest
  should "render preview" do
    version = create(:version)
    preview rubygem: version.rubygem, number: version.number, platform: version.platform, version_gid: version.to_gid

    assert_text "Version:"
    assert_text "#{version.rubygem.name} (#{version.number})"
    assert_link "#{version.rubygem.name} (#{version.number})", href: view_context.rubygem_version_path(version.rubygem.slug, version.slug)

    preview rubygem: version.rubygem, number: version.number, platform: version.platform, version_gid: nil

    assert_text "Version:"
    assert_text "#{version.rubygem.name} (#{version.number})"
    refute_link

    preview rubygem: version.rubygem, number: version.number, platform: version.platform do
      version.destroy!
    end

    assert_text "Version:"
    assert_text "#{version.rubygem.name} (#{version.number})"
    refute_link
  end
end
