require "test_helper"

class Events::RubygemEvent::OwnerComponentTest < ComponentTest
  test "owner added" do
    user = create(:user, handle: "Owner")
    preview("events/rubygem_event/owner/added", user:)

    assert_text "New owner added:"
    assert_text "Authorized by:"
    assert_link user.handle
    assert_link "Authorizer"

    preview("events/rubygem_event/owner/added", scenario: :without_actor)

    assert_text "New owner added:"
    assert_text "Authorized by:"
    assert_link user.handle
    assert_no_link "Authorizer"

    preview("events/rubygem_event/owner/added", scenario: :without_authorizer)

    assert_text "New owner added: Owner", exact: true
    assert_link user.handle
  end

  test "owner added with a deleted user" do
    user = create(:user, handle: "Owner")
    preview("events/rubygem_event/owner/added", user:) do
      user.destroy!
    end

    assert_text "New owner added:"
    assert_text "Authorized by:"
    assert_no_link "Owner"
  end
end
