require "test_helper"

class Events::UserEvent::ApiKey::DeletedComponentTest < ComponentTest
  should "render preview" do
    preview

    assert_text "Name: example", exact: true, normalize_ws: false
  end
end
