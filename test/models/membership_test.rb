require "test_helper"

class MembershipTest < ActiveSupport::TestCase
  should belong_to(:organization)
  should belong_to(:user)

  setup do
    @owner = create(:user)
    @organization = create(:organization, owners: [@owner])
    @user = create(:user)
  end

  should "not require the invited_by field if the membership is the owner from onboarding" do
    membership = Membership.new(organization: @organization, user: @user, invited_by: @owner, confirmed_at: Time.zone.now)

    assert_predicate membership, :valid?
  end

  should "be unconfirmed by default" do
    membership = Membership.create!(organization: @organization, user: @user, invited_by: @owner)

    refute_predicate membership, :confirmed?
  end

  should "have a default role" do
    membership = Membership.create!(organization: @organization, user: @user, invited_by: @owner)

    assert_predicate membership, :maintainer?
  end

  context ".confirmed" do
    should "be confirmed with confirmed_at" do
      membership = Membership.create!(organization: @organization, user: @user, invited_by: @owner, confirmed_at: 5.minutes.ago)

      assert_includes(Membership.confirmed, membership)
    end
  end

  context "#create" do
    should "set the invitation_expires_at timestamp" do
      freeze_time do
        membership = Membership.create!(organization: @organization, user: @user, invited_by: @owner)

        assert_equal membership.invitation_expires_at, Gemcutter::MEMBERSHIP_INVITE_EXPIRES_AFTER.from_now
      end
    end
  end

  context "#confirm!" do
    should "set the confirmed_at timestamp to now" do
      freeze_time do
        membership = Membership.create!(organization: @organization, user: @user, invited_by: @owner)
        membership.confirm!

        assert_equal Time.zone.now, membership.confirmed_at
      end
    end
  end

  context "#refresh_invitation!" do
    should "update the invitation_expires_at timestamp" do
      freeze_time do
        membership = Membership.create!(organization: @organization, user: @user, invited_by: @owner, invitation_expires_at: 1.day.ago)
        membership.refresh_invitation!

        assert_equal Gemcutter::MEMBERSHIP_INVITE_EXPIRES_AFTER.from_now, membership.invitation_expires_at
      end
    end
  end
end
