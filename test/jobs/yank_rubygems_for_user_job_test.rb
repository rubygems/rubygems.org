# frozen_string_literal: true

require "test_helper"

class YankRubygemsForUserJobTest < ActiveJob::TestCase
  test "yanks all versions for all of the user's rubygems" do
    security_user = create(:user, email: "security@rubygems.org")
    user = create(:user)
    rubygem1 = create(:rubygem, owners: [user])
    version1 = create(:version, rubygem: rubygem1)
    rubygem2 = create(:rubygem, owners: [user])
    version2 = create(:version, rubygem: rubygem2)

    YankRubygemsForUserJob.perform_now(user: user)

    assert_predicate version1.reload, :yanked?
    assert_predicate version2.reload, :yanked?
    assert_equal 2, security_user.deletions.count
  end

  test "skips already yanked versions" do
    create(:user, email: "security@rubygems.org")
    user = create(:user)
    rubygem = create(:rubygem, owners: [user])
    create(:version, rubygem: rubygem, indexed: false, yanked_at: Time.now.utc)

    assert_no_difference "Deletion.count" do
      YankRubygemsForUserJob.perform_now(user: user)
    end
  end

  test "force yanks versions with high download counts" do
    security_user = create(:user, email: "security@rubygems.org")
    user = create(:user)
    rubygem = create(:rubygem, owners: [user])
    version = create(:version, rubygem: rubygem)
    GemDownload.increment(100_001, rubygem_id: rubygem.id, version_id: version.id)

    YankRubygemsForUserJob.perform_now(user: user)

    assert_predicate version.reload, :yanked?
    assert_equal 1, security_user.deletions.count
  end

  test "handles user with no rubygems" do
    user = create(:user)

    assert_nothing_raised do
      YankRubygemsForUserJob.perform_now(user: user)
    end
  end

  test "yanks multiple versions of the same rubygem" do
    security_user = create(:user, email: "security@rubygems.org")
    user = create(:user)
    rubygem = create(:rubygem, owners: [user])
    version1 = create(:version, rubygem: rubygem, number: "1.0.0")
    version2 = create(:version, rubygem: rubygem, number: "2.0.0")

    YankRubygemsForUserJob.perform_now(user: user)

    assert_predicate version1.reload, :yanked?
    assert_predicate version2.reload, :yanked?
    assert_equal 2, security_user.deletions.count
  end
end
