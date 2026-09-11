# frozen_string_literal: true

require "test_helper"

class ReconcileVersionPermissionsTest < ActiveJob::TestCase
  setup do
    @current_user = create(:admin_github_user, :is_admin)
    @version = create(:version)
    @action = Avo::Actions::ReconcileVersionPermissions.new(record: @version, resource: nil, user: @current_user, view: :show)

    view_context = mock
    avo = mock
    view_context.stubs(:avo).returns(avo)
    avo.stubs(:resources_audit_path).returns("resources_audit_path")
    Avo::Current.stubs(:view_context).returns(view_context)
  end

  should "be registered on the version resource" do
    action_classes = Avo::Resources::Version.new.get_actions.pluck(:class)

    assert_includes action_classes, Avo::Actions::ReconcileVersionPermissions
  end

  should "ask for confirmation naming the selected version" do
    message = Data.define(:record).new(@version).instance_exec(&Avo::Actions::ReconcileVersionPermissions.message)

    assert_includes message, @version.full_name
  end

  should "reconcile permissions and purge fastly for gem and gemspec paths" do
    fs = mock
    RubygemFs.stubs(:instance).returns(fs)
    fs.expects(:reconcile_permissions).with("gems/#{@version.gem_file_name}")
    fs.expects(:reconcile_permissions).with("quick/Marshal.4.8/#{@version.full_name}.gemspec.rz")

    assert_enqueued_with(job: FastlyPurgeJob, args: [path: "gems/#{@version.gem_file_name}", soft: false]) do
      assert_enqueued_with(job: FastlyPurgeJob, args: [path: "quick/Marshal.4.8/#{@version.full_name}.gemspec.rz", soft: false]) do
        @action.handle(**action_args)
      end
    end

    audit = Audit.sole

    assert_equal "Reconcile version permissions", audit.action
    assert_equal @version, audit.auditable
  end

  private

  def action_args
    {
      current_user: @current_user,
      resource: nil,
      records: [@version],
      fields: { comment: "Fixing download access regression" },
      query: nil
    }
  end
end
