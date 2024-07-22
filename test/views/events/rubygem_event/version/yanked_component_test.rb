require "test_helper"

class Events::RubygemEvent::Version::YankedComponentTest < ComponentTest
  should "render preview" do
    rubygem = create(:rubygem, name: "RubyGem1")
    version = create(:version, number: "0.0.1", rubygem:)
    create(:deletion, version: version)

    preview rubygem: version.rubygem, number: version.number, platform: version.platform

    assert_text "Version: RubyGem1 (0.0.1)\nYanked by: Yanker", exact: true
    assert_link "RubyGem1 (0.0.1)", href: view_context.rubygem_version_path(version.rubygem.slug, version.slug)
    assert_link "Yanker", href: view_context.profile_path(version.yanker.display_id)
  end
end
