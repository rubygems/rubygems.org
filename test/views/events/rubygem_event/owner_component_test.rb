require "test_helper"

class Events::RubygemEvent::OwnerComponentTest < ComponentTest
  test "owner added" do
    user = create(:user, handle: "Owner")
    preview("events/rubygem_event/owner/added", user:)

    assert_text "New owner added: OwnerAuthorized by: Authorizer", exact: true
    assert_link user.handle, href: view_context.profile_path(user.display_id)
    assert_link "Authorizer", href: view_context.profile_path(user.display_id)

    preview("events/rubygem_event/owner/added", scenario: :without_actor)

    assert_text "New owner added: OwnerAuthorized by: Authorizer", exact: true
    assert_link user.handle, href: view_context.profile_path(user.display_id)
    assert_no_link "Authorizer"

    preview("events/rubygem_event/owner/added", scenario: :without_authorizer)

    assert_text "New owner added: Owner", exact: true
    assert_link user.handle, href: view_context.profile_path(user.display_id)
  end

  test "owner added with a deleted user" do
    user = create(:user, handle: "Owner")
    preview("events/rubygem_event/owner/added", user:) do
      user.destroy!
    end

    assert_text "New owner added: OwnerAuthorized by: Authorizer", exact: true
    assert_no_link "Owner"
  end
end
