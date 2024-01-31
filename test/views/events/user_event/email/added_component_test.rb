require "test_helper"

class Events::UserEvent::Email::AddedComponentTest < ComponentTest
  should "render preview" do
    preview

    assert_text "user@example.com"
  end
end
