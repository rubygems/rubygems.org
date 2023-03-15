require "test_helper"

class DeleteUserJobTest < ActiveJob::TestCase
  test "sends deletion complete on success" do
    user = create(:user)
    rubygem = create(:ownership, user:).rubygem
    version = create(:version, rubygem:)
    Mailer.expects(:deletion_complete).with(user.email)
    DeleteUserJob.perform_now(user:)

    assert_predicate user, :destroyed?
    assert_predicate version.reload, :yanked?
  end

  test "sends deletion failed on failure" do
    user = create(:user)
    user.expects(:destroy).returns(false)
    Mailer.expects(:deletion_failed).with(user.email)
    DeleteUserJob.perform_now(user:)

    refute_predicate user.reload, :destroyed?
  end
end
