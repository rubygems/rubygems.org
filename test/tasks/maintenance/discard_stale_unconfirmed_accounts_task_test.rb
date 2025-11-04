# frozen_string_literal: true

require "test_helper"

class Maintenance::DiscardStaleUnconfirmedAccountsTaskTest < ActiveSupport::TestCase
  test "#process discards stale unconfirmed users" do
    stale_unconfirmed_user = create(:user, :unconfirmed, created_at: actionable_timestamp)

    refute_predicate stale_unconfirmed_user, :discarded?

    Maintenance::DiscardStaleUnconfirmedAccountsTask.process(stale_unconfirmed_user)

    assert_predicate stale_unconfirmed_user, :discarded?
  end

  test "#collection returns discardable users" do
    confirmed_user = create(:user, created_at: actionable_timestamp)
    recent_unconfirmed_user = create(:user, :unconfirmed, created_at: 7.days.ago)
    stale_unconfirmed_user = create(:user, :unconfirmed, created_at: actionable_timestamp)
    discarded_user = create(:user, :unconfirmed, created_at: actionable_timestamp)
    discarded_user.discard!

    discardable_users = Maintenance::DiscardStaleUnconfirmedAccountsTask.collection

    assert_includes discardable_users, stale_unconfirmed_user

    assert_not_includes discardable_users, confirmed_user
    assert_not_includes discardable_users, recent_unconfirmed_user
    assert_not_includes discardable_users, discarded_user
  end

  def actionable_timestamp
    Maintenance::DiscardStaleUnconfirmedAccountsTask::UNCONFIRMED_USER_RETENTION_DAYS.ago
  end
end
