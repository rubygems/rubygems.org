require "test_helper"

class DeleteUserJobTest < ActiveJob::TestCase
  test "sends deletion complete on success" do
    user = create(:user)
    rubygem = create(:ownership, user:).rubygem
    version = create(:version, rubygem:)
    Mailer.expects(:deletion_complete).with(user.email).returns(mock(deliver_later: nil))
    DeleteUserJob.perform_now(user:)

    assert_predicate user, :destroyed?
    assert_predicate version.reload, :yanked?
  end

  test "sends deletion failed on failure" do
    user = create(:user)
    create(:oidc_id_token, user:)
    Mailer.expects(:deletion_failed).with(user.email).returns(mock(deliver_later: nil))
    DeleteUserJob.perform_now(user:)

    refute_predicate user.reload, :destroyed?
  end

  test "succeeds with api key" do
    user = create(:user)
    create(:api_key, user:)
    Mailer.expects(:deletion_complete).with(user.email).returns(mock(deliver_later: nil))

    DeleteUserJob.perform_now(user:)
  end

  test "succeeds with api key used to push version" do
    user = create(:user)
    api_key = create(:api_key, user:)
    create(:version, pusher_api_key: api_key, pusher: user)
    Mailer.expects(:deletion_complete).with(user.email).returns(mock(deliver_later: nil))

    DeleteUserJob.perform_now(user:)
  end
end
