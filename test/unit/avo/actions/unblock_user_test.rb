require "test_helper"

class UnblockUserTest < ActiveSupport::TestCase
  setup do
    @user = create(:user, :blocked)
    @current_user = create(:admin_github_user)
    @resource = UserResource.new.hydrate(model: @user)
  end

  test "unblock user" do
    args = {
      current_user: @current_user,
      resource: @resource,
      models: [@user],
      fields: {
        comment: "Unblocking incorrectly flagged user"
      }
    }

    action = UnblockUser.new(model: @user, resource: @resource, user: @current_user, view: :edit)
    action.handle(**args)

    refute_predicate @user.reload, :blocked?
  end
end
