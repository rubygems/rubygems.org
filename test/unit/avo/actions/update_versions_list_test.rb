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

  test "enqueues a v1 versions list update" do
    perform_action("1")

    assert_enqueued_jobs 1, only: UpdateVersionsListJob
    assert_enqueued_with(job: UpdateVersionsListJob, args: [version: 1])
  end

  test "enqueues a v2 versions list update" do
    perform_action("2")

    assert_enqueued_jobs 1, only: UpdateVersionsListJob
    assert_enqueued_with(job: UpdateVersionsListJob, args: [version: 2])
  end

  test "enqueues v1 and v2 versions list updates" do
    perform_action("both")

    assert_enqueued_jobs 2, only: UpdateVersionsListJob
    assert_enqueued_with(job: UpdateVersionsListJob, args: [version: 1])
    assert_enqueued_with(job: UpdateVersionsListJob, args: [version: 2])
  end

  test "shows an error for unsupported versions" do
    perform_action("3")

    assert_no_enqueued_jobs only: UpdateVersionsListJob
    assert_equal [type: :error, body: "Unsupported compact index version: 3", timeout: nil], @action.response[:messages]
  end

  private

  def perform_action(version)
    @action.handle(
      fields: {
        comment: "Regenerating versions list",
        "version" => version
      },
      current_user: @current_user,
      resource: nil,
      records: [],
      query: nil
    )
  end
end
