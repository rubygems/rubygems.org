require "test_helper"

class Events::UserEvent::Login::SuccessComponentTest < ComponentTest
  should "render preview" do
    preview scenario: :password

    assert_text "MFA Method: None", exact: true, normalize_ws: false
  end
end
