# frozen_string_literal: true

require "test_helper"

class TemporaryPushGrantActionsTest < ActiveSupport::TestCase
  setup do
    @grant = create(:temporary_push_grant)
    create(:temporary_push_grant_artifact, temporary_push_grant: @grant)
    @operator_one = create(:admin_github_user, :is_admin, login: "operator-one")
    @operator_two = create(:admin_github_user, :is_admin, login: "operator-two")
  end

  should "record each step of the grant lifecycle as an audit by the acting operator" do
    run_action(Avo::Actions::ApproveTemporaryPushGrant, @operator_one, conflict_disclosure: "No conflicts")
    run_action(Avo::Actions::ApproveTemporaryPushGrant, @operator_two, conflict_disclosure: "No conflicts")
    run_action(Avo::Actions::RecordTemporaryPushGrantReview, @operator_one, reviewer: "reviewer", notes: "Suite passes")
    activate = run_action(Avo::Actions::ActivateTemporaryPushGrant, @operator_two)
    run_action(Avo::Actions::SuspendTemporaryPushGrant, @operator_one, comment: "Owner replied; clarifying wishes")
    run_action(Avo::Actions::ResumeTemporaryPushGrant, @operator_one, comment: "Owner confirmed they cannot release")
    run_action(Avo::Actions::RevokeTemporaryPushGrant, @operator_two, comment: "Owner objected to the release")

    audits = @grant.audits.order(:id)

    assert_equal ["Approve Temporary Push Grant", "Approve Temporary Push Grant", "Record Technical Review",
                  "Activate Temporary Push Grant", "Suspend Temporary Push Grant", "Resume Temporary Push Grant",
                  "Revoke Temporary Push Grant"], audits.map(&:action)
    assert_equal %w[operator-one operator-two operator-one operator-two operator-one operator-one operator-two],
      audits.map { it.admin_github_user.login }
    assert_equal "No conflicts", audits.first.audited_changes.dig("fields", "conflict_disclosure")

    mail = ActionMailer::Base.deliveries.last
    key = mail.body.to_s[/rubygems_\h{48}/]

    assert_equal [@grant.grantee.email], mail.to
    assert_equal @grant.reload.api_key.hashed_key, Digest::SHA256.hexdigest(key)
    refute_includes activate.response[:messages].to_json, key
    refute_includes audits.map { it.audited_changes.to_json }.join, key
    assert_equal "Owner objected to the release", @grant.revocation_reason
    assert_predicate @grant.api_key, :expired?
  end

  should "refuse activation without approvals, showing why and leaving no key or audit" do
    action = run_action(Avo::Actions::ActivateTemporaryPushGrant, @operator_one)

    assert_equal :error, action.response[:messages].sole[:type]
    assert_match "needs 2 independent operator approvals", action.response[:messages].sole[:body]
    assert_nil @grant.reload.activated_at
    assert_empty Audit.all
    assert_empty ApiKey.where(name: "temporary-push-grant-#{@grant.id}")
  end

  should "not be authorized for operators outside the rubygems.org team" do
    @operator_one.update!(is_admin: false)
    action = Avo::Actions::RevokeTemporaryPushGrant.new(record: @grant, resource: resource, user: @operator_one, view: :show)

    refute_predicate action, :authorized?
  end

  should "be registered on the grant resource" do
    action_classes = Avo::Resources::TemporaryPushGrant.new.get_actions.pluck(:class)

    assert_includes action_classes, Avo::Actions::ActivateTemporaryPushGrant
    assert_includes action_classes, Avo::Actions::RevokeTemporaryPushGrant
  end

  private

  def resource
    Avo::Resources::TemporaryPushGrant.new.hydrate(record: @grant)
  end

  def run_action(klass, operator, comment: "Operator decision recorded on the request issue", **fields)
    Avo::Current.stubs(:user).returns(operator)
    action = klass.new(record: @grant, resource:, user: operator, view: :show)
    action.handle(current_user: operator, resource:, records: [@grant.reload], fields: { comment:, **fields }, query: nil)
    action
  end
end
