require "test_helper"

class Events::RubygemEvent::Owner::AddedComponentTest < ComponentTest
  should "render preview" do
    preview user: create(:user)

    assert_text "New owner added:"
    assert_text "Owner"
    assert_text "Authorized by:"
    assert_text "Authorizer"
  end
end
