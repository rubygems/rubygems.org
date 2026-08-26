# frozen_string_literal: true

require "test_helper"

class SyncAdvisoriesTest < ActiveJob::TestCase
  setup do
    @current_user = create(:admin_github_user, :is_admin)
    @action = Avo::Actions::SyncAdvisories.new

    view_context = mock
    avo = mock
    view_context.stubs(:avo).returns(avo)
    avo.stubs(:resources_audit_path).returns("resources_audit_path")
    Avo::Current.stubs(:view_context).returns(view_context)
  end

  should "be registered on the advisory resource" do
    action_classes = Avo::Resources::Advisory.new.get_actions.pluck(:class)

    assert_includes action_classes, Avo::Actions::SyncAdvisories
  end

  should "enqueue a forced advisory sync" do
    perform_action

    assert_enqueued_jobs 1, only: SyncAdvisoriesJob
    assert_enqueued_with(job: SyncAdvisoriesJob, args: [force: true])
  end

  should "record an Avo audit against the operator" do
    comment = "Warming the advisories table before enabling the public flag"

    perform_action(comment:)

    audit = Audit.sole

    assert_equal comment, audit.comment
    assert_equal "Sync Advisories", audit.action
    assert_equal @current_user, audit.auditable
    assert_equal "Advisory sync job scheduled", @action.response.dig(:messages, 0, :body)
  end

  should "be visible to rubygems.org operators on the index" do
    action_context = Data.define(:current_user, :view).new(current_user: @current_user, view: :index)

    assert action_context.instance_exec(&Avo::Actions::SyncAdvisories.visible)
  end

  should "not be visible on the show page" do
    action_context = Data.define(:current_user, :view).new(current_user: @current_user, view: :show)

    refute action_context.instance_exec(&Avo::Actions::SyncAdvisories.visible)
  end

  private

  def perform_action(comment: "Warming the advisories table")
    Advisory::OSV::Fetcher.any_instance.expects(:fetch).never

    @action.handle(
      fields: { comment: },
      current_user: @current_user,
      resource: nil,
      records: [],
      query: nil
    )
  end
end
