require "test_helper"

class Events::UserEvent::ApiKey::CreatedComponentTest < ComponentTest
  should "render preview" do
    preview

    assert_text "Name: example\nScopes: push\nMFA: Not required", exact: true, normalize_ws: false
  end
end
