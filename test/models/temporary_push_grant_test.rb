# frozen_string_literal: true

require "test_helper"

class TemporaryPushGrantTest < ActiveSupport::TestCase
  setup do
    @owner = create(:user)
    @rubygem = create(:rubygem, owners: [@owner])
    @grant = create(:temporary_push_grant, rubygem: @rubygem)
    @artifact = create(:temporary_push_grant_artifact, temporary_push_grant: @grant)
    @operator_one = create(:admin_github_user, :is_admin, login: "operator-one")
    @operator_two = create(:admin_github_user, :is_admin, login: "operator-two")
  end

  context "activation" do
    should "require two independent approvals and a technical review of the current scope" do
      assert_includes @grant.activation_errors, "needs 2 independent operator approvals of its current scope"
      assert_includes @grant.activation_errors, "needs an independent technical review of its current scope"

      @grant.approve!(@operator_one, conflict_disclosure: "None")
      @grant.approve!(@operator_one, conflict_disclosure: "None, re-approving") # same person twice

      refute_predicate @grant, :approved?

      @grant.approve!(@operator_two, conflict_disclosure: "None")
      @grant.record_technical_review!(reviewer: "reviewer", notes: "Reviewed")

      assert_empty @grant.activation_errors
    end

    should "void approvals and the review when the approved scope changes" do
      approve_and_review(@grant)
      create(:temporary_push_grant_artifact, temporary_push_grant: @grant, platform: "java")

      refute_predicate @grant, :approved?
      refute_predicate @grant, :technically_reviewed?
      assert_raises(ActiveRecord::RecordInvalid) { @grant.activate! }

      @grant.reload.update!(version: "1.0.1")

      refute_predicate @grant, :approved?
    end

    should "refuse the requester or grantee as approver or technical reviewer" do
      requester = create(:admin_github_user, :is_admin, login: "Requester")

      assert_raises(ActiveRecord::RecordInvalid) { @grant.approve!(requester, conflict_disclosure: "None") }
      assert_raises(ActiveRecord::RecordInvalid) { @grant.record_technical_review!(reviewer: "GRANTEE", notes: "x") }
      assert_empty @grant.approvals
    end

    should "wait for the owner response deadline, and need a recorded reason to shorten it" do
      grant = build(:temporary_push_grant, outreach_sent_at: 2.days.ago, response_deadline_at: 1.day.from_now)

      refute_predicate grant, :valid?
      assert_includes grant.errors[:shortened_response_reason].join, "14 days"

      grant.shortened_response_reason = "Actively exploited; approved by two operators"
      grant.save!
      create(:temporary_push_grant_artifact, temporary_push_grant: grant)
      approve_and_review(grant)

      assert_equal ["cannot be activated before the owner response deadline"], grant.activation_errors
    end

    should "require the grantee to have MFA enabled" do
      @grant.grantee.update!(mfa_level: :disabled, totp_seed: nil)
      approve_and_review(@grant)

      assert_equal ["grantee must have multi-factor authentication enabled"], @grant.activation_errors
    end

    should "email a publish-only MFA key that expires 72 hours later to the grantee, without changing ownership" do
      approve_and_review(@grant)

      freeze_time do
        @grant.activate!
        mail = ActionMailer::Base.deliveries.last

        assert_equal [@grant.grantee.email], mail.to
        key = mail.body.to_s[/rubygems_\h{48}/]
        api_key = ApiKey.find_by!(hashed_key: Digest::SHA256.hexdigest(key))

        assert_equal @grant.api_key, api_key
        assert_equal %i[push_rubygem], api_key.scopes
        assert api_key.mfa
        assert_equal @grant.grantee, api_key.owner
        assert_equal 72.hours.from_now, @grant.expires_at
        assert_equal @grant.expires_at, api_key.expires_at
        assert_equal :active, @grant.status
      end
      assert_equal [@owner], @rubygem.reload.owners_including_unconfirmed.to_a
      assert_raises(ActiveRecord::RecordInvalid) { @grant.activate! }
    end

    should "not activate when the key cannot be emailed" do
      approve_and_review(@grant)
      Mailer.any_instance.stubs(:temporary_push_grant_activated).raises(RuntimeError, "mail down")

      assert_raises(RuntimeError) { @grant.activate! }
      assert_nil @grant.reload.activated_at
      assert_empty ApiKey.where(name: "temporary-push-grant-#{@grant.id}")
    end

    should "fix the approved scope once activated" do
      approve_and_review(@grant)
      @grant.activate!

      assert_raises(ActiveRecord::RecordInvalid) { create(:temporary_push_grant_artifact, temporary_push_grant: @grant, platform: "java") }
      assert_raises(ActiveRecord::RecordInvalid) { @grant.approve!(create(:admin_github_user, :is_admin, login: "late"), conflict_disclosure: "None") }
    end
  end

  context "suspension and revocation" do
    setup do
      approve_and_review(@grant)
      @grant.activate!
    end

    should "pause and resume without extending the original expiry" do
      expires_at = @grant.expires_at
      travel 1.hour
      @grant.suspend!("Owner replied")

      assert_equal :suspended, @grant.status
      @grant.resume!

      assert_equal :active, @grant.status
      assert_equal expires_at, @grant.reload.expires_at
    end

    should "revoke the grant and expire its key" do
      @grant.revoke!("Evidence of compromise")

      assert_equal :revoked, @grant.status
      assert_predicate @grant.api_key.reload, :expired?
      assert_raises(ActiveRecord::RecordInvalid) { @grant.revoke!("again") }
      assert_raises(ActiveRecord::RecordInvalid) { @grant.resume! }
    end
  end

  context "a correction" do
    setup do
      approve_and_review(@grant)
      @grant.activate!
      @correction = create(:temporary_push_grant, rubygem: @rubygem, grantee: @grant.grantee, original_grant: @grant,
        version: "1.0.1", correction_reason: "1.0.0 shipped a broken native extension")
      create(:temporary_push_grant_artifact, temporary_push_grant: @correction)
    end

    should "need its own approvals and review, and expire with the original grant" do
      refute_empty @correction.activation_errors
      approve_and_review(@correction)
      travel 10.hours

      @correction.activate!

      assert_equal @grant.expires_at, @correction.expires_at
      assert_equal @grant.expires_at, @correction.api_key.expires_at
    end

    should "still need MFA when activated minutes before the original expiry" do
      approve_and_review(@correction)
      travel_to(@grant.expires_at - 5.minutes) { @correction.activate! }

      assert_predicate @correction.api_key, :short_lived?
      refute @correction.api_key.mfa_authorized?(nil)
    end

    should "be the only correction, and only for an unexpired, unrevoked original" do
      second = build(:temporary_push_grant, rubygem: @rubygem, original_grant: @grant, correction_reason: "again")

      refute_predicate second, :valid?
      refute_predicate build(:temporary_push_grant, original_grant: @grant, correction_reason: "x"), :valid? # other gem
      refute_predicate build(:temporary_push_grant, rubygem: @rubygem, original_grant: @correction, correction_reason: "x"), :valid?

      approve_and_review(@correction)

      travel_to(@grant.expires_at + 1.second) do
        assert_includes @correction.activation_errors, "original grant has expired, so a new grant is required"
      end
    end

    should "not re-authorize the original artifacts" do
      @correction.artifacts.sole.update_column(:sha256, @artifact.sha256)
      approve_and_review(@correction)

      assert_includes @correction.activation_errors, "correction cannot re-authorize artifacts approved by the original grant"
    end

    should "stop publishing when the original grant is suspended or revoked" do
      approve_and_review(@correction)
      @correction.activate!
      version = build(:version, rubygem: @rubygem, number: "1.0.1", platform: "ruby")

      @grant.suspend!("Owner replied")

      assert_match "suspended", @correction.reload.upload_denial_reason(@rubygem, version)
    end
  end

  private

  def approve_and_review(grant)
    grant.approve!(@operator_one, conflict_disclosure: "None")
    grant.approve!(@operator_two, conflict_disclosure: "None")
    grant.record_technical_review!(reviewer: "reviewer", notes: "Suite passes; diff and built gems reviewed.")
  end
end
