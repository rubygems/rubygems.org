# frozen_string_literal: true

require "test_helper"

class Maintenance::NotifyCacheExposedUsersTaskTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  setup do
    @task = Maintenance::NotifyCacheExposedUsersTask.new
  end

  def mark_revoked(user)
    user.record_event!(Events::UserEvent::CACHE_EXPOSURE_KEY_REVOKED, name: ApiKey::LEGACY_KEY_NAME)
  end

  context "#collection" do
    should "surface each revoked owner once, however many keys were revoked" do
      user = create(:user)
      mark_revoked(user)
      mark_revoked(user)

      assert_equal [user], @task.collection.order(:id).to_a
    end

    should "still surface revoked owners after the revoke task has expired their keys" do
      user = create(:user)
      create(:api_key, :legacy_broad, owner: user, key: "will-revoke")

      # Revoke -> Notify order: run the real revoke task first, which expires the key.
      revoke = Maintenance::RevokeCacheExposedApiKeysTask.new
      revoke.collection.each { |key| revoke.process(key) }

      refute_predicate ApiKey.legacy.unexpired, :exists?, "revoke should have expired the key"
      assert_includes @task.collection, user
    end

    should "exclude blocked owners" do
      active = create(:user)
      blocked = create(:user)
      blocked.update_column(:blocked_email, "blocked@rubygems.org")
      mark_revoked(active)
      mark_revoked(blocked)

      assert_includes @task.collection, active
      refute_includes @task.collection, blocked
    end

    should "exclude users who already received this notice" do
      notified = create(:user)
      pending = create(:user)
      mark_revoked(notified)
      mark_revoked(pending)
      notified.record_event!(
        Events::UserEvent::EMAIL_SENT,
        action: Maintenance::NotifyCacheExposedUsersTask::NOTICE_MAILER_ACTION,
        mailer: Maintenance::NotifyCacheExposedUsersTask::NOTICE_MAILER_NAME
      )

      assert_includes @task.collection, pending
      refute_includes @task.collection, notified
    end

    should "not treat a same-action email from a different mailer as this notice" do
      user = create(:user)
      mark_revoked(user)
      # Same action string, recorded by a different mailer: the incident audience must
      # still include this user, because the dedup matches action AND mailer.
      user.record_event!(
        Events::UserEvent::EMAIL_SENT,
        action: Maintenance::NotifyCacheExposedUsersTask::NOTICE_MAILER_ACTION,
        mailer: "some_other_mailer"
      )

      assert_includes @task.collection, user
    end
  end

  context "#collection canary bounds" do
    setup do
      @users = create_list(:user, 3).sort_by(&:id)
      @users.each { |user| mark_revoked(user) }
    end

    should "apply min_user_id as an inclusive lower bound" do
      @task.min_user_id = @users[1].id

      assert_equal @users[1..], @task.collection.order(:id).to_a
    end

    should "apply max_user_id as an inclusive upper bound" do
      @task.max_user_id = @users[1].id

      assert_equal @users[0..1], @task.collection.order(:id).to_a
    end

    should "apply both bounds together" do
      @task.min_user_id = @users[1].id
      @task.max_user_id = @users[1].id

      assert_equal [@users[1]], @task.collection.order(:id).to_a
    end

    should "be invalid when max_user_id is below min_user_id" do
      @task.min_user_id = 10
      @task.max_user_id = 5

      refute_predicate @task, :valid?
      assert_includes @task.errors[:max_user_id], "must be greater than or equal to min_user_id"
    end
  end

  context "#process" do
    should "queue one cache-exposure notice for the user" do
      user = create(:user)

      assert_enqueued_email_with CacheExposureMailer, :cache_exposure_notice, args: [user] do
        @task.process(user)
      end
    end
  end
end
