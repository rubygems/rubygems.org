require "test_helper"

class Events::UserEvent::Email::VerifiedComponentTest < ComponentTest
  should "render preview" do
    preview rubygem: create(:rubygem)

    assert_text "user@example.com", exact: true
  end
end
