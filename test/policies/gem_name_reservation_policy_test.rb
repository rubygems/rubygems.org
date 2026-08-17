# frozen_string_literal: true

require "test_helper"
class GemNameReservationPolicyTest < PolicyTestCase
  setup do
    @owner = create(:user, handle: "owner")
    @admin = create(:user, handle: "admin")
    @maintainer = create(:user, handle: "maintainer")
    @guest = create(:user)
    @organization = create(:organization, owners: [@owner], admins: [@admin], maintainers: [@maintainer])
    @gem_name_reservation = create(:gem_name_reservation, organization: @organization)
  end

  def policy!(user)
    Pundit.policy!(user, @gem_name_reservation)
  end

  context "#new?" do
    should "be authorized for org admins and owners" do
      assert_authorized @owner, :new?
      assert_authorized @admin, :new?

      refute_authorized @maintainer, :new?
      refute_authorized @guest, :new?
    end
  end

  context "#create?" do
    should "be authorized for org admins and owners" do
      assert_authorized @owner, :create?
      assert_authorized @admin, :create?

      refute_authorized @maintainer, :create?
      refute_authorized @guest, :create?
    end
  end

  context "#destroy?" do
    should "be authorized for org admins and owners" do
      assert_authorized @owner, :destroy?
      assert_authorized @admin, :destroy?

      refute_authorized @maintainer, :destroy?
      refute_authorized @guest, :destroy?
    end
  end

  context "with a reservation that has no organization" do
    setup do
      @gem_name_reservation = create(:gem_name_reservation, organization: nil)
    end

    should "not be authorized for anyone" do
      refute_authorized @owner, :create?
      refute_authorized @owner, :destroy?
    end
  end
end
