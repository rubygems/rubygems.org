# frozen_string_literal: true

require "test_helper"

class OwnersHelperTest < ActionView::TestCase
  context "#prior_ownerships_of" do
    setup do
      @rubygem = create(:rubygem)
    end

    should "exclude current owners" do
      user = create(:user)
      create(:ownership, rubygem: @rubygem, user: user)

      assert_empty prior_ownerships_of(@rubygem)
    end

    should "include a closed stint for a user who is not a current owner" do
      user = create(:user)
      create(:ownership, rubygem: @rubygem, user: user).destroy

      assert_equal [user], prior_ownerships_of(@rubygem).map(&:user)
    end

    should "list a user more than once for multiple closed stints" do
      user = create(:user)
      create(:ownership, rubygem: @rubygem, user: user).destroy
      create(:ownership, rubygem: @rubygem, user: user).destroy

      assert_equal [user, user], prior_ownerships_of(@rubygem).map(&:user)
    end

    should "order by most recent removal descending" do
      older = create(:user)
      newer = create(:user)

      create(:ownership, rubygem: @rubygem, user: older).destroy
      travel 1.day do
        create(:ownership, rubygem: @rubygem, user: newer).destroy
      end

      assert_equal [newer, older], prior_ownerships_of(@rubygem).map(&:user)
    end

    should "exclude a discarded prior owner" do
      user = create(:user)
      create(:ownership, rubygem: @rubygem, user: user).destroy
      user.discard!

      assert_empty prior_ownerships_of(@rubygem)
    end

    should "include a stint the prior owner has marked private" do
      user = create(:user)
      create(:historical_ownership, rubygem: @rubygem, user: user, removed_at: Time.current, private_at: Time.current)

      assert_equal [user], prior_ownerships_of(@rubygem).map(&:user)
    end
  end
end
