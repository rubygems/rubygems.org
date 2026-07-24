# frozen_string_literal: true

require "test_helper"

class Maintenance::NotifyCacheExposedInactiveUsersTaskTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  setup do
    @task = Maintenance::NotifyCacheExposedInactiveUsersTask.new
  end

  # A legacy key that was already expired before the sweep (self-reset / password
  # reset / secret-scanning auto-expire), so the revoke task never touched it.
  def inactive_in_scope_key(owner)
    key = create(:api_key, :legacy_broad, owner: owner)
    key.expire!
    key
  end

  # A key the real revoke sweep expires + stamps CACHE_EXPOSURE_KEY_REVOKED for.
  def revoke_a_key_for(owner)
    key = create(:api_key, :legacy_broad, owner: owner)
    Maintenance::RevokeCacheExposedApiKeysTask.new.process(key)
    key
  end

  context "#collection" do
    should "surface an owner whose in-scope legacy key was already inactive" do
      user = create(:user)
      inactive_in_scope_key(user)

      assert_includes @task.collection, user
    end

    should "surface each inactive owner once, however many inactive keys they had" do
      user = create(:user)
      inactive_in_scope_key(user)
      inactive_in_scope_key(user)

      assert_equal [user], @task.collection.order(:id).to_a
    end

    should "exclude an owner the revoke sweep already revoked a key for (they get the active notice)" do
      user = create(:user)
      # After the sweep the key is expired AND in-scope, so it matches ApiKey.legacy.expired —
      # but the owner carries CACHE_EXPOSURE_KEY_REVOKED, so this cohort must skip them.
      revoke_a_key_for(user)

      refute_includes @task.collection, user
    end

    should "exclude an owner who has both a revoked key and a separately-inactive key" do
      user = create(:user)
      inactive_in_scope_key(user) # pre-existing dead key
      revoke_a_key_for(user)      # live key the sweep revokes -> REVOKED event

      refute_includes @task.collection, user, "the active notice covers them; don't double-mail"
    end

    should "exclude an owner whose legacy key is still active" do
      user = create(:user)
      # Unexpired: this is the active cohort (revoke + active-notify handle them), not here.
      create(:api_key, :legacy_broad, owner: user)

      refute_includes @task.collection, user
    end

    should "exclude an owner whose expired legacy-named key is OIDC-backed" do
      token = create(:oidc_id_token)
      token.api_key.update_columns(name: ApiKey::LEGACY_KEY_NAME, expires_at: 1.day.ago)

      refute_includes @task.collection, token.api_key.owner
    end

    should "exclude blocked owners" do
      active = create(:user)
      blocked = create(:user)
      blocked.update_column(:blocked_email, "blocked@rubygems.org")
      inactive_in_scope_key(active)
      inactive_in_scope_key(blocked)

      assert_includes @task.collection, active
      refute_includes @task.collection, blocked
    end

    should "exclude users who already received this inactive notice" do
      notified = create(:user)
      pending = create(:user)
      inactive_in_scope_key(notified)
      inactive_in_scope_key(pending)
      notified.record_event!(
        Events::UserEvent::EMAIL_SENT,
        action: Maintenance::NotifyCacheExposedInactiveUsersTask::NOTICE_MAILER_ACTION,
        mailer: Maintenance::NotifyCacheExposedInactiveUsersTask::NOTICE_MAILER_NAME
      )

      assert_includes @task.collection, pending
      refute_includes @task.collection, notified
    end
  end

  context "#collection canary bounds" do
    setup do
      @users = create_list(:user, 3).sort_by(&:id)
      @users.each { |user| inactive_in_scope_key(user) }
    end

    should "apply min_user_id as an inclusive lower bound" do
      @task.min_user_id = @users[1].id

      assert_equal @users[1..], @task.collection.order(:id).to_a
    end

    should "apply max_user_id as an inclusive upper bound" do
      @task.max_user_id = @users[1].id

      assert_equal @users[0..1], @task.collection.order(:id).to_a
    end

    should "be invalid when max_user_id is below min_user_id" do
      @task.min_user_id = 10
      @task.max_user_id = 5

      refute_predicate @task, :valid?
      assert_includes @task.errors[:max_user_id], "must be greater than or equal to min_user_id"
    end
  end

  context "#process" do
    should "queue one inactive-cohort notice for the user" do
      user = create(:user)

      assert_enqueued_email_with CacheExposureMailer, :cache_exposure_inactive_notice, args: [user] do
        @task.process(user)
      end
    end
  end
end
