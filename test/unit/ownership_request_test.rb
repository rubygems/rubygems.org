require "test_helper"

class OwnershipRequestTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @rubygem = create(:rubygem)
  end

  context "#factory" do
    should "be valid with factory" do
      assert_predicate build(:ownership_request, user: @user, rubygem: @rubygem), :valid?
    end

    should "be valid with approved trait factory" do
      assert_predicate build(:ownership_request, :approved, user: @user, rubygem: @rubygem), :valid?
    end

    should "be valid with close trait factory" do
      assert_predicate build(:ownership_request, :closed, user: @user, rubygem: @rubygem), :valid?
    end

    should "be valid with ownership call trait factory" do
      assert_predicate build(:ownership_request, :with_ownership_call, user: @user, rubygem: @rubygem), :valid?
    end

    should "be valid with ownership call and approved traits factory" do
      assert_predicate build(:ownership_request, :with_ownership_call, :approved, user: @user, rubygem: @rubygem), :valid?
    end
  end

  context "#create" do
    should "create a call with open status" do
      ownership_request = @rubygem.ownership_requests.create(user: @user, note: "valid note")
      assert_predicate ownership_request, :opened?
    end

    should "not create a call without note" do
      ownership_request = build(:ownership_request, user: @user, rubygem: @rubygem, note: nil)
      refute_predicate ownership_request, :valid?
      assert_contains ownership_request.errors[:note], "can't be blank"
    end

    should "not create a call with note longer than 64000 chars" do
      ownership_request = build(:ownership_request, user: @user, rubygem: @rubygem,
                                note: "r" * (Gemcutter::MAX_TEXT_FIELD_LENGTH + 1))
      refute_predicate ownership_request, :valid?
      assert_contains ownership_request.errors[:note], "is too long (maximum is 64000 characters)"
    end

    should "not create multiple calls for same user and rubygem" do
      create(:ownership_request, user: @user, rubygem: @rubygem)
      ownership_request = build(:ownership_request, user: @user, rubygem: @rubygem)
      refute_predicate ownership_request, :valid?
      assert_contains ownership_request.errors[:user_id], "has already been taken"
    end
  end

  context "#approve" do
    setup do
      @ownership_request = create(:ownership_request, user: @user, rubygem: @rubygem)
      @approver = create(:user)
      create(:ownership, rubygem: @rubygem, user: @approver)
    end
    should "return true" do
      assert @ownership_request.approve(@approver)
    end
    should "update approver" do
      @ownership_request.approve(@approver)
      assert_predicate @ownership_request, :approved?
      assert_equal @approver, @ownership_request.approver
    end

    should "create confirmed ownership" do
      @ownership_request.approve(@approver)
      ownership = Ownership.find_by(user: @user, rubygem: @rubygem)
      assert_equal @approver, ownership.authorizer
      assert_predicate ownership, :confirmed?
    end

    should "return false if cannot update status" do
      OwnershipRequest.any_instance.stubs(:update).returns(false)
      refute @ownership_request.approve(@approver)
      assert_nil Ownership.find_by(user: @user, rubygem: @rubygem)
    end
  end

  context "#close" do
    setup do
      @ownership_request = create(:ownership_request, user: @user, rubygem: @rubygem)
    end

    should "return false if cannot close" do
      other_user = create(:user)
      refute @ownership_request.close(other_user)
      refute_predicate @ownership_request, :closed?
    end

    should "return true if closed by requester" do
      assert @ownership_request.close(@user)
      assert_predicate @ownership_request, :closed?
    end

    should "return true if closed by owner" do
      other_user = create(:user)
      create(:ownership, user: other_user, rubygem: @rubygem)
      assert @ownership_request.close(other_user)
      assert_predicate @ownership_request, :closed?
    end

    should "return false if cannot update status" do
      OwnershipRequest.any_instance.stubs(:update).returns(false)
      refute @ownership_request.close(@user)
      refute_predicate @ownership_request, :closed?
    end
  end

  context "#close_all" do
    should "return count of records closed" do
      create_list(:ownership_request, 3, rubygem: @rubygem)
      assert @rubygem.ownership_requests.close_all
    end

    should "return 0 no records updated" do
      assert @rubygem.ownership_requests.close_all
    end
  end
end
