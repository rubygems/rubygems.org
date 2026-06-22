# frozen_string_literal: true

require "test_helper"

class UpdateVersionsListTest < ActiveJob::TestCase
  setup do
    @current_user = create(:admin_github_user, :is_admin)
    @action = Avo::Actions::UpdateVersionsList.new

    view_context = mock
    avo = mock
    view_context.stubs(:avo).returns(avo)
    avo.stubs(:resources_audit_path).returns("resources_audit_path")
    Avo::Current.stubs(:view_context).returns(view_context)
  end

  test "enqueues a versions list update" do
    perform_action

    assert_enqueued_jobs 1, only: UpdateVersionsListJob
    assert_enqueued_with(job: UpdateVersionsListJob, args: [version: 2])
  end

  private

  def perform_action
    @action.handle(
      fields: { comment: "Regenerating versions list" },
      current_user: @current_user,
      resource: nil,
      records: [],
      query: nil
    )
  end
end
