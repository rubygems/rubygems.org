require "test_helper"

class Events::RubygemEvent::Owner::ConfirmedComponentTest < ComponentTest
  should "render preview" do
    preview user: create(:user)

    assert_text "New owner added: Owner", exact: true, normalize_ws: false
  end
end
