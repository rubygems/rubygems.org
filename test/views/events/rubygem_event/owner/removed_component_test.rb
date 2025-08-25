require "test_helper"

class Events::RubygemEvent::Owner::RemovedComponentTest < ComponentTest
  should "render preview" do
    user = create(:user)
    preview user: user, rubygem: create(:rubygem)

    assert_text "Owner removed:"
    assert_text "Owner"
    assert page.has_content?("Owner removed:")
  end
end
