require "test_helper"

class MembershipTest < ActiveSupport::TestCase
  should belong_to(:organization)
  should belong_to(:user)

  setup do
    @organization = FactoryBot.create(:organization)
    @user = FactoryBot.create(:user)
  end

  should "be unconfirmed by default" do
    membership = Membership.create!(organization: @organization, user: @user)

    assert_not(membership.confirmed?)
    assert_empty(Membership.confirmed)
  end

  should "be confirmed with confirmed_at" do
    membership = Membership.create!(organization: @organization, user: @user, confirmed_at: Time.zone.now)

    assert_predicate(membership, :confirmed?)
    assert_equal(Membership.confirmed, [membership])
  end

  should "have a default role" do
    membership = Membership.create!(organization: @organization, user: @user)

    assert_predicate membership, :maintainer?
  end
end
