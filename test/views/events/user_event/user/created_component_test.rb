require "test_helper"

class Events::UserEvent::User::CreatedComponentTest < ComponentTest
  should "render preview" do
    preview

    assert_text "Email: user@example.com", exact: true, normalize_ws: false
  end
end
