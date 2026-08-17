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
    stub_audit_redirect
    args = {
      current_user: @current_user,
      resource: @resource,
      records: [@user],
      fields: {
        comment: "Deleting at the user's request"
      },
      query: nil
    }

    assert_enqueued_with(job: DeleteUserJob, args: [user: @user, actor: @current_user, keep_gems_published: false]) do
      @action.handle(**args)
    end
  end

  should "enqueue and audit a deletion for every selected user" do
    stub_audit_redirect

    other_user = create(:user)
    args = {
      current_user: @current_user,
      resource: @resource,
      records: [@user, other_user],
      fields: {
        comment: "Deleting users from a malicious campaign"
      },
      query: nil
    }

    assert_difference "Audit.count", 2 do
      assert_enqueued_jobs 2, only: DeleteUserJob do
        @action.handle(**args)
      end
    end
    audit_models = Audit.order(:id).map { |audit| audit.audited_changes.fetch("models") }

    assert_equal [
      [@user.to_global_id.uri.to_s],
      [other_user.to_global_id.uri.to_s]
    ], audit_models
    assert_equal ["Account deletion has been scheduled for 2 users"],
      @action.response[:messages].pluck(:body)
  end

  should "continue deleting eligible users when another selected user is protected" do
    stub_audit_redirect
    protected_user = create(:user)
    rubygem = create(:rubygem, name: "protected-gem-in-bulk-deletion", owners: [protected_user])
    create(:version, rubygem:, created_at: 31.days.ago)
    args = {
      current_user: @current_user,
      resource: @resource,
      records: [protected_user, @user],
      fields: {
        comment: "Deleting users from a malicious campaign"
      },
      query: nil
    }

    assert_difference "Audit.count", 1 do
      assert_enqueued_with(job: DeleteUserJob, args: [user: @user, actor: @current_user, keep_gems_published: false]) do
        @action.handle(**args)
      end
    end
    assert_equal [@user], Audit.all.map(&:auditable)
    assert_equal [
      "Account deletion has been scheduled for 1 user",
      "Deletion was not scheduled for 1 user. #{Avo::Actions::DeleteUser.blocked_reason}"
    ], @action.response[:messages].pluck(:body)
  end

  should "continue deleting users after an enqueue failure without auditing the failure" do
    stub_audit_redirect
    failing_user = create(:user)
    other_user = create(:user)
    args = {
      current_user: @current_user,
      resource: @resource,
      records: [@user, failing_user, other_user],
      fields: {
        comment: "Deleting users from a malicious campaign"
      },
      query: nil
    }

    reject_enqueue_for(failing_user) do
      assert_error_reported(ActiveJob::EnqueueError) do
        assert_difference "Audit.count", 2 do
          assert_enqueued_jobs 2, only: DeleteUserJob do
            @action.handle(**args)
          end
        end
      end
    end
    assert_equal [@user, other_user].sort_by(&:id), Audit.all.map(&:auditable).sort_by(&:id)
    assert_equal [
      "Account deletion has been scheduled for 2 users",
      "Deletion could not be scheduled for 1 user. The failure has been reported."
    ], @action.response[:messages].pluck(:body)
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

    assert_no_difference "Audit.count" do
      assert_no_enqueued_jobs only: DeleteUserJob do
        @action.handle(**args)
      end
    end
    assert_includes @action.response.dig(:messages, 0, :body), Avo::Actions::DeleteUser.blocked_reason
  end

  should "enqueue deletion for a sole owner when keeping gems published" do
    stub_audit_redirect
    rubygem = create(:rubygem, name: "old-gem-preserved-for-deleted-user", owners: [@user])
    create(:version, rubygem:, created_at: 31.days.ago)
    args = {
      current_user: @current_user,
      resource: @resource,
      records: [@user],
      fields: {
        comment: "Deleting at the user's request",
        keep_gems_published: "1"
      },
      query: nil
    }

    assert_enqueued_with(job: DeleteUserJob, args: [user: @user, actor: @current_user, keep_gems_published: true]) do
      @action.handle(**args)
    end
  end

  should "not enqueue deletion when the user is the sole owner of a gem version with too many downloads" do
    rubygem = create(:rubygem, name: "popular-gem-owned-by-deleted-user", owners: [@user])
    version = create(:version, rubygem:)
    GemDownload.increment(100_001, rubygem_id: rubygem.id, version_id: version.id)
    args = {
      current_user: @current_user,
      resource: @resource,
      records: [@user],
      fields: {
        comment: "Deleting at the user's request"
      },
      query: nil
    }

    assert_no_difference "Audit.count" do
      assert_no_enqueued_jobs only: DeleteUserJob do
        @action.handle(**args)
      end
    end
    assert_includes @action.response.dig(:messages, 0, :body), Avo::Actions::DeleteUser.blocked_reason
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

  should "ask for confirmation for multiple selected users" do
    other_user = create(:user)
    query = User.where(id: [@user.id, other_user.id])
    action = Avo::Actions::DeleteUser.new(record: nil, resource: @resource, user: @current_user, view: :index, query:)

    assert_includes action.get_message, "delete 2 selected users"
    assert_equal "Delete Users", action.confirm_button_label
  end

  private

  def stub_audit_redirect
    view_context = mock
    avo = mock
    view_context.stubs(:avo).returns(avo)
    avo.stubs(:resources_audit_path).returns("resources_audit_path")
    Avo::Current.stubs(:view_context).returns(view_context)
  end

  def reject_enqueue_for(user)
    callback = lambda do |job|
      throw :abort if job.arguments.first.fetch(:user) == user
    end
    DeleteUserJob.set_callback(:enqueue, :before, callback)

    yield
  ensure
    DeleteUserJob.skip_callback(:enqueue, :before, callback)
  end
end
