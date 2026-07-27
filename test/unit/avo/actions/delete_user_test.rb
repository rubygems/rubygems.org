# frozen_string_literal: true

require "test_helper"

class DeleteUserTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @user = create(:user)
    @current_user = create(:admin_github_user, :is_admin)
    @resource = Avo::Resources::User.new.hydrate(record: @user)
    @action = Avo::Actions::DeleteUser.new(record: @user, resource: @resource, user: @current_user, view: :show)
  end

  should "enqueue the same deletion job used by profile deletion" do
    args = {
      current_user: @current_user,
      resource: @resource,
      records: [@user],
      fields: {
        comment: "Deleting at the user's request"
      },
      query: nil
    }

    assert_enqueued_with(job: DeleteUserJob, args: [user: @user]) do
      @action.handle(**args)
    end
  end

  should "ask for confirmation naming the user" do
    message = @action.get_message

    assert_includes message, @user.handle
    assert_includes message, @user.email
  end
end
