require "test_helper"

class Events::RubygemEvent::Owner::RemovedComponentTest < ComponentTest
  should "render preview" do
    preview user: create(:user), rubygem: create(:rubygem)

    assert_text "Owner removed: Owner", exact: true, normalize_ws: false
  end
end
