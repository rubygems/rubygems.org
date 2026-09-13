# frozen_string_literal: true

require "test_helper"

class UsersHelperTest < ActionView::TestCase
  context "#prior_rubygems_of" do
    setup do
      @user = create(:user)
    end

    should "exclude a gem the user currently owns" do
      rubygem = create(:rubygem)
      create(:ownership, user: @user, rubygem: rubygem)

      assert_empty prior_rubygems_of(@user)
    end

    should "include a closed stint for a gem no longer owned" do
      rubygem = create(:rubygem)
      create(:version, rubygem: rubygem)
      create(:ownership, user: @user, rubygem: rubygem).destroy

      assert_equal [rubygem], prior_rubygems_of(@user).map(&:rubygem)
    end

    should "exclude a gem currently owned even with an old closed stint" do
      rubygem = create(:rubygem)
      create(:version, rubygem: rubygem)
      create(:ownership, user: @user, rubygem: rubygem).destroy
      create(:ownership, user: @user, rubygem: rubygem)

      assert_empty prior_rubygems_of(@user)
    end

    should "exclude a gem with no versions" do
      rubygem = create(:rubygem)
      create(:ownership, user: @user, rubygem: rubygem).destroy

      assert_empty prior_rubygems_of(@user)
    end

    should "order by most recent removal descending" do
      older = create(:rubygem)
      create(:version, rubygem: older)
      newer = create(:rubygem)
      create(:version, rubygem: newer)

      create(:ownership, user: @user, rubygem: older).destroy
      travel 1.day do
        create(:ownership, user: @user, rubygem: newer).destroy
      end

      assert_equal [newer, older], prior_rubygems_of(@user).map(&:rubygem)
    end

    should "return one entry for a gem with two closed stints" do
      rubygem = create(:rubygem)
      create(:version, rubygem: rubygem)
      create(:ownership, user: @user, rubygem: rubygem).destroy
      create(:ownership, user: @user, rubygem: rubygem).destroy

      assert_equal [rubygem], prior_rubygems_of(@user).map(&:rubygem)
    end

    should "exclude a stint the user has marked private" do
      rubygem = create(:rubygem)
      create(:version, rubygem: rubygem)
      create(:historical_ownership, user: @user, rubygem: rubygem, removed_at: Time.current, private_at: Time.current)

      assert_empty prior_rubygems_of(@user)
    end
  end

  context "#rubygems_with_history_for" do
    should "combine current and prior gems sorted by downloads descending" do
      less_downloaded = create(:rubygem)
      GemDownload.increment(5, rubygem_id: less_downloaded.id)
      more_downloaded = create(:rubygem)
      GemDownload.increment(10, rubygem_id: more_downloaded.id)

      prior_ownership = create(:historical_ownership, rubygem: more_downloaded, removed_at: Time.current)

      result = rubygems_with_history_for([less_downloaded], [prior_ownership])

      assert_equal [[more_downloaded, prior_ownership.removed_at], [less_downloaded, nil]], result
    end

    should "return only current gems when there are no prior gems" do
      rubygem = create(:rubygem)

      assert_equal [[rubygem, nil]], rubygems_with_history_for([rubygem], [])
    end

    should "return only prior gems when there are no current gems" do
      rubygem = create(:rubygem)
      prior_ownership = create(:historical_ownership, rubygem: rubygem, removed_at: Time.current)

      assert_equal [[rubygem, prior_ownership.removed_at]], rubygems_with_history_for([], [prior_ownership])
    end

    should "return an empty array when there are no current or prior gems" do
      assert_empty rubygems_with_history_for([], [])
    end
  end

  context "obfuscate_email" do
    should "obfuscate standard email" do
      assert_equal "g*******@r************.org", obfuscate_email("gem-user@rubygems-test.org")
    end

    should "obfuscate email with short local part" do
      assert_equal "j**@g****.com", obfuscate_email("joe@gmail.com")
    end

    should "handle very short email parts" do
      assert_equal "*@*.io", obfuscate_email("j@x.io")
    end

    should "handle two character local part" do
      assert_equal "h*@r************.org", obfuscate_email("hi@rubygems-test.org")
    end

    should "handle single character local part" do
      assert_equal "*@r************.org", obfuscate_email("a@rubygems-test.org")
    end

    should "handle subdomain in TLD" do
      assert_equal "u***@m***.co.uk", obfuscate_email("user@mail.co.uk")
    end

    should "return nil for nil input" do
      assert_nil obfuscate_email(nil)
    end

    should "return empty string for empty input" do
      assert_equal "", obfuscate_email("")
    end

    should "return original for invalid email without @" do
      assert_equal "notanemail", obfuscate_email("notanemail")
    end

    should "return original for invalid email without domain" do
      assert_equal "user@", obfuscate_email("user@")
    end
  end
end
