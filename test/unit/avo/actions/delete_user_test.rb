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

  should "enqueue an admin-initiated deletion" do
    args = {
      current_user: @current_user,
      resource: @resource,
      records: [@user],
      fields: {
        comment: "Deleting at the user's request"
      },
      query: nil
    }

    assert_enqueued_with(job: DeleteUserJob, args: [user: @user, initiated_by: :admin]) do
      @action.handle(**args)
    end
  end

  should "not enqueue deletion when the user is the sole owner of an old gem version" do
    rubygem = create(:rubygem, name: "old-gem-owned-by-deleted-user", owners: [@user])
    create(:version, rubygem:, created_at: 31.days.ago)
    args = {
      current_user: @current_user,
      resource: @resource,
      records: [@user],
      fields: {
        comment: "Deleting at the user's request"
      },
      query: nil
    }

    assert_no_enqueued_jobs only: DeleteUserJob do
      @action.handle(**args)
    end
    assert_equal Avo::Actions::DeleteUser.blocked_reason, @action.response.dig(:messages, 0, :body)
  end

  should "ask for confirmation naming the user" do
    message = @action.get_message

    assert_includes message, @user.handle
    assert_includes message, @user.email
  end

  should "ask for confirmation naming a user without a handle" do
    @user.update!(handle: nil)

    message = @action.get_message

    assert_includes message, "delete user ##{@user.id} with #{@user.email}"
  end
end
