require "test_helper"

class ChangeOrganizationHandleTest < ActiveSupport::TestCase
  setup do
    @organization = create(:organization, handle: "old-handle")
    @current_user = create(:admin_github_user, :is_admin)
    @resource = Avo::Resources::Organization.new.hydrate(record: @organization)
    @action = Avo::Actions::ChangeOrganizationHandle.new(
      record: @organization,
      resource: @resource,
      user: @current_user,
      view: :show
    )
  end

  should "change organization handle" do
    args = {
      current_user: @current_user,
      resource: @resource,
      records: [@organization],
      fields: {
        comment: "Onboarding a new organization 1234567",
        new_handle: "new-handle"
      }.with_indifferent_access,
      query: nil
    }

    @action.handle(**args)

    assert_equal "new-handle", @organization.reload.handle

    audit = @organization.audits.sole

    assert_equal @organization, audit.auditable
    assert_equal "Change Organization Handle", audit.action
    assert_equal @current_user, audit.admin_github_user
    assert_equal({ "new_handle" => "new-handle" }, audit.audited_changes["fields"])
  end

  should "ask for confirmation" do
    action_mock = Data.define(:record).new(record: @organization)

    message = action_mock.instance_exec(&Avo::Actions::ChangeOrganizationHandle.message)

    assert_includes message, "old-handle"
  end

  should "be visible" do
    action_mock = Data.define(:current_user, :view).new(current_user: @current_user, view: :show)

    assert action_mock.instance_exec(&Avo::Actions::ChangeOrganizationHandle.visible)
  end
end
