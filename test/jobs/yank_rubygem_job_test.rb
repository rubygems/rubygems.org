# frozen_string_literal: true

require "test_helper"

class YankRubygemJobTest < ActiveJob::TestCase
  test "yanks all versions of the rubygem" do
    security_user = create(:user, email: "security@rubygems.org")
    user = create(:user)
    rubygem = create(:rubygem, owners: [user])
    version1 = create(:version, rubygem: rubygem, number: "1.0.0")
    version2 = create(:version, rubygem: rubygem, number: "2.0.0")

    YankRubygemJob.perform_now(rubygem: rubygem)

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
      YankRubygemJob.perform_now(rubygem: rubygem)
    end
  end

  test "force yanks versions with high download counts" do
    security_user = create(:user, email: "security@rubygems.org")
    user = create(:user)
    rubygem = create(:rubygem, owners: [user])
    version = create(:version, rubygem: rubygem)
    GemDownload.increment(100_001, rubygem_id: rubygem.id, version_id: version.id)

    YankRubygemJob.perform_now(rubygem: rubygem)

    assert_predicate version.reload, :yanked?
    assert_equal 1, security_user.deletions.count
  end

  test "handles rubygem with no versions" do
    user = create(:user)
    rubygem = create(:rubygem, owners: [user])

    assert_nothing_raised do
      YankRubygemJob.perform_now(rubygem: rubygem)
    end
  end
end
