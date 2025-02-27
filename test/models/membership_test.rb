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

  should "have a default role" do
    membership = Membership.create!(organization: @organization, user: @user)

    assert_predicate membership, :maintainer?
  end

  context ".confirmed" do
    should "be confirmed with confirmed_at" do
      membership = Membership.create!(organization: @organization, user: @user, confirmed_at: Time.zone.now)

      assert_predicate(membership, :confirmed?)
      assert_equal(Membership.confirmed, [membership])
    end
  end

  context "#create" do
    should "set the invitation_expires_at timestamp" do
      freeze_time do
        membership = Membership.create!(organization: @organization, user: @user)
        assert_equal membership.invitation_expires_at, Gemcutter::MEMBERSHIP_INVITE_EXPIRES_AFTER.from_now
      end
    end
  end

  context "#confirm!" do
    should "set the confirmed_at timestamp to now" do
      freeze_time do
        membership = Membership.create!(organization: @organization, user: @user)
        membership.confirm!

        assert_equal Time.zone.now, membership.confirmed_at
      end
    end
  end

  context "#refresh_invitation" do
    should "update the invitation_expires_at timestamp" do
      freeze_time do
        membership = Membership.create!(organization: @organization, user: @user, invitation_expires_at: 1.day.ago)
        membership.refresh_invitation

        assert_equal Gemcutter::MEMBERSHIP_INVITE_EXPIRES_AFTER.from_now, membership.invitation_expires_at
      end
    end
  end
end
