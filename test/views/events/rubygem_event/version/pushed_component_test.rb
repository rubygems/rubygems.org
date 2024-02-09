require "test_helper"

class Events::RubygemEvent::Version::PushedComponentTest < ComponentTest
  should "render preview" do
    preview rubygem: create(:rubygem, name: "RubyGem3"), number: "1.0.0", platform: "ruby"

    assert_text "Version: RubyGem3 (1.0.0)\nPushed by: Pusher", exact: true
  end
end
