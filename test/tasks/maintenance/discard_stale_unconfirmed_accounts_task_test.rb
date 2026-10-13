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
    confirmed_user = create(:user, **discardable_attributes(email_confirmed: true))
    stale_unconfirmed_user = create(:user, **discardable_attributes)
    recent_unconfirmed_user = create(:user, **discardable_attributes(created_at: 7.days.ago))
    ancient_unconfirmed_user = create(:user, **discardable_attributes(created_at: Time.new(2010, 5, 5).utc))

    discarded_user = create(:user, **discardable_attributes)
    discarded_user.discard!

    rubygem_owner = create(:user, **discardable_attributes)
    create(:ownership, user: rubygem_owner)

    organization_owner = create(:user, **discardable_attributes)
    create(:membership, user: organization_owner)

    unconfirmed_user_with_credentials = create(:user, **discardable_attributes)
    create(:webauthn_credential, user: unconfirmed_user_with_credentials)

    unconfirmed_user_with_previous_push = create(:user, **discardable_attributes)
    create(:version, pusher_id: unconfirmed_user_with_previous_push.id)

    unconfirmed_user_with_previous_login = create(:user, **discardable_attributes)
    create(:events_user_event, user: unconfirmed_user_with_previous_login)

    discardable_users = Maintenance::DiscardStaleUnconfirmedAccountsTask.collection

    assert_includes discardable_users, stale_unconfirmed_user

    assert_not_includes discardable_users, confirmed_user
    assert_not_includes discardable_users, recent_unconfirmed_user
    assert_not_includes discardable_users, ancient_unconfirmed_user
    assert_not_includes discardable_users, discarded_user
    assert_not_includes discardable_users, rubygem_owner
    assert_not_includes discardable_users, organization_owner
    assert_not_includes discardable_users, unconfirmed_user_with_credentials
    assert_not_includes discardable_users, unconfirmed_user_with_previous_push
    assert_not_includes discardable_users, unconfirmed_user_with_previous_login
  end

  def discardable_attributes(overrides = {})
    {
      created_at: actionable_timestamp,
      email_confirmed: false,
      policies_acknowledged_at: nil
    }.merge(overrides)
  end

  def actionable_timestamp
    Maintenance::DiscardStaleUnconfirmedAccountsTask::UNCONFIRMED_USER_RETENTION_DAYS.ago - 1
  end
end
