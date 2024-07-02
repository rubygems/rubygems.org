require "test_helper"

class MembershipTest < ActiveSupport::TestCase
  should belong_to(:org)
  should belong_to(:user)

  setup do
    @org = FactoryBot.create(:org)
    @user = FactoryBot.create(:user)
  end

  should "be unconfirmed by default" do
    membership = Membership.create!(org: @org, user: @user)

    assert_not(membership.confirmed?)
    assert_empty(Membership.confirmed)
  end

  should "be confirmed with confirmed_at" do
    membership = Membership.create!(org: @org, user: @user, confirmed_at: Time.zone.now)

    assert_predicate(membership, :confirmed?)
    assert_equal(Membership.confirmed, [membership])
  end
end
