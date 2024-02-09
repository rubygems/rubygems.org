require "test_helper"

class Events::RubygemEvent::Version::UnyankedComponentTest < ComponentTest
  should "render preview" do
    version = create(:version)
    preview rubygem: version.rubygem, number: version.number, platform: version.platform

    assert_text "Version: #{version.rubygem.name} (#{version.number})", exact: true
    assert_link "#{version.rubygem.name} (#{version.number})", href: view_context.rubygem_version_path(version.rubygem.slug, version.slug)

    preview rubygem: version.rubygem, number: version.number, platform: version.platform, version_gid: nil

    assert_text "Version: #{version.rubygem.name} (#{version.number})", exact: true
    refute_link

    preview rubygem: version.rubygem, number: version.number, platform: version.platform do
      version.destroy!
    end

    assert_text "Version: #{version.rubygem.name} (#{version.number})", exact: true
    refute_link
  end
end
