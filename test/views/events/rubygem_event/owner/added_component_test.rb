require "test_helper"

class Events::RubygemEvent::Owner::AddedComponentTest < ComponentTest
  should "render preview" do
    preview user: create(:user)

    assert_text "New owner added: OwnerAuthorized by: Authorizer", exact: true, normalize_ws: false
  end
end
