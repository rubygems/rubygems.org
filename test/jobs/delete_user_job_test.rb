require "test_helper"

class DeleteUserJobTest < ActiveJob::TestCase
  test "sends deletion complete on success" do
    user = create(:user)
    rubygem = create(:ownership, user:).rubygem
    version = create(:version, rubygem:)

    assert_delete user
    assert_predicate version.reload, :yanked?
    refute_predicate rubygem.reload, :indexed?
  end

  test "sends deletion failed on failure" do
    user = create(:user)

    User.any_instance.expects(:yank_gems).raises(ActiveRecord::RecordNotDestroyed)
    DeleteUserJob.perform_now(user:)

    refute_predicate user.reload, :destroyed?
    refute_predicate user, :deleted_at
  end

  test "succeeds with api key" do
    user = create(:user)
    create(:api_key, owner: user)

    assert_delete user
  end

  test "succeeds with api key used to push version" do
    user = create(:user)
    api_key = create(:api_key, owner: user)
    version = create(:version, pusher_api_key: api_key, pusher: user)

    assert_delete user
    assert_predicate user.reload, :deleted_at
    assert_predicate api_key.reload, :expired?
    User.unscoped do
      assert_equal api_key.reload.owner, user
      assert_equal version.reload.pusher, user
    end
    assert_equal version.reload.pusher_api_key, api_key
  end

  test "succeeds with version deletion" do
    user = create(:user)
    rubygem = create(:rubygem, owners: [user])
    api_key = create(:api_key, owner: user)
    version = create(:version, rubygem:, pusher_api_key: api_key, pusher: user)
    deletion = create(:deletion, version: version, user: user)

    assert_delete user
    assert_predicate user.reload, :deleted_at
    assert_predicate api_key.reload, :expired?
    User.unscoped do
      assert_equal api_key.reload.owner, user
      assert_equal version.reload.pusher, user
      assert_equal deletion.reload.user, user
    end
    assert_equal version.reload.pusher_api_key, api_key
    assert_empty rubygem.reload.owners
    assert_empty user.ownerships
    assert_predicate version.reload, :yanked?
    refute_predicate rubygem.reload, :indexed?
  end

  test "succeeds with rubygem with shared ownership" do
    user = create(:user)
    other_user = create(:user)
    rubygem = create(:rubygem, owners: [user, other_user])
    api_key = create(:api_key, owner: user)
    version = create(:version, rubygem:, pusher_api_key: api_key, pusher: user)
    other_version = create(:version, rubygem:, pusher: other_user)

    assert_delete user
    assert_predicate user.reload, :deleted_at
    assert_predicate api_key.reload, :expired?
    User.unscoped do
      assert_equal api_key.reload.owner, user
      assert_equal version.reload.pusher, user
    end
    assert_equal version.reload.pusher_api_key, api_key
    assert_equal [other_user], rubygem.reload.owners
    assert_empty user.ownerships
    assert_predicate rubygem.reload, :indexed?
    refute_predicate version.reload, :yanked?
    refute_predicate other_version.reload, :yanked?
    assert_equal other_user, other_version.pusher
  end

  test "succeeds with webauthn credentials" do
    user = create(:user)
    user_credential = create(:webauthn_credential, user: user)

    assert_delete user
    assert_deleted user_credential
  end

  test "succeeds with subscription" do
    user = create(:user)
    subscription = create(:subscription, user: user)

    assert_delete user
    assert_deleted subscription
  end

  test "succeeds with ownership calls and requests" do
    user = create(:user)
    rubygem = create(:rubygem, owners: [user])
    other_user = create(:user)
    other_rubygem = create(:rubygem, owners: [other_user])

    closed_call = create(:ownership_call, rubygem: rubygem, user: user, status: :closed)
    open_call = create(:ownership_call, rubygem: rubygem, user: user)

    other_call = create(:ownership_call, rubygem: other_rubygem, user: other_user)
    closed_request = create(:ownership_request, ownership_call: other_call, rubygem: rubygem, user: user, status: :closed)
    approved_request = create(:ownership_request, ownership_call: other_call, rubygem: rubygem, user: user, status: :approved)
    open_request = create(:ownership_request, ownership_call: other_call, rubygem: rubygem, user: user)
    other_request = create(:ownership_request, ownership_call: open_call, rubygem: rubygem, user: other_user)

    assert_delete user
    assert_deleted open_call
    assert_deleted closed_call
    assert_deleted open_request
    assert_deleted approved_request
    assert_deleted closed_request
    assert_deleted other_request
    assert_equal other_call.reload.user, other_user
  end

  def assert_delete(user)
    Mailer.expects(:deletion_complete).with(user.email).returns(mock(deliver_later: nil))
    DeleteUserJob.new(user:).perform(user:)

    refute_predicate user, :destroyed?
    assert_predicate user.reload, :deleted_at
  end

  def assert_deleted(record)
    error = assert_raises(ActiveRecord::RecordNotFound) { assert_predicate record.reload, :destroyed? }

    assert_equal record.class.name, error.model, "Expected #{record.class} to be class of not found error"
  end
end
