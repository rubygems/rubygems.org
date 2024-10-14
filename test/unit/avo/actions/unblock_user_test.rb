require "test_helper"

class UnblockUserTest < ActiveSupport::TestCase
  setup do
    @user = create(:user, :blocked)
    @current_user = create(:admin_github_user, :is_admin)
    @resource = Avo::Resources::User.new.hydrate(record: @user)
    @action = Avo::Actions::UnblockUser.new(record: @user, resource: @resource, user: @current_user, view: :edit)
  end

  should "unblock user" do
    args = {
      current_user: @current_user,
      resource: @resource,
      records: [@user],
      fields: {
        comment: "Unblocking incorrectly flagged user"
      },
      query: nil
    }

    @action.handle(**args)

    refute_predicate @user.reload, :blocked?
  end

  # Avo does not have an easy and direct way to test the message & visible class attributes.
  # calling the lambda directly will raise an error because Avo requires the entire app to be loaded.

  should "ask for confirmation" do
    action_mock = Data.define(:record).new(record: @user)

    assert_not_nil action_mock.instance_exec(&Avo::Actions::UnblockUser.message)
  end

  should "be visible" do
    action_mock = Data.define(:current_user, :view, :record).new(current_user: @current_user, view: :show, record: @user)

    assert action_mock.instance_exec(&Avo::Actions::UnblockUser.visible)
  end

  context "when the user is not blocked" do
    setup do
      @user = create(:user)
    end

    should "not be visible" do
      action_mock = Data.define(:current_user, :view, :record).new(current_user: @current_user, view: :show, record: @user)

      refute action_mock.instance_exec(&Avo::Actions::UnblockUser.visible)
    end
  end
end
