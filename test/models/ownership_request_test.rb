require "test_helper"

class OwnershipRequestTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

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

    should "update approver" do
      @ownership_request.approve!(@approver)

      assert_predicate @ownership_request, :approved?
      assert_equal @approver, @ownership_request.approver
    end

    should "send emails" do
      @ownership_request.approve!(@approver)

      assert_enqueued_emails 3
    end

    should "create confirmed ownership" do
      @ownership_request.approve!(@approver)
      ownership = Ownership.find_by(user: @user, rubygem: @rubygem)

      assert_equal @approver, ownership.authorizer
      assert_predicate ownership, :confirmed?
    end

    should "raises if cannot update status" do
      OwnershipRequest.any_instance.stubs(:update!).raises(ActiveRecord::RecordInvalid)

      assert_raises(ActiveRecord::RecordInvalid) { @ownership_request.approve!(@approver) }
      assert_nil Ownership.find_by(user: @user, rubygem: @rubygem)
    end

    should "raises if ownership cannot be confirmed" do
      Ownership.any_instance.stubs(:update!).raises(ActiveRecord::RecordNotSaved)

      assert_raises(ActiveRecord::RecordNotSaved) { @ownership_request.approve!(@approver) }
      assert_nil Ownership.find_by(user: @user, rubygem: @rubygem)
      refute_predicate @ownership_request.reload, :approved?

      assert_enqueued_emails 0
    end
  end

  context "#close" do
    setup do
      @ownership_request = create(:ownership_request, user: @user, rubygem: @rubygem)
    end

    should "close and not send emails if closed by requester" do
      @ownership_request.close!(@user)

      assert_predicate @ownership_request, :closed?

      assert_enqueued_emails 0
    end

    should "close and sends email to requester if closed by owner" do
      other_user = create(:user)
      create(:ownership, user: other_user, rubygem: @rubygem)

      @ownership_request.close!(other_user)

      assert_predicate @ownership_request, :closed?

      assert_enqueued_emails 1
    end

    should "raises if cannot update status" do
      OwnershipRequest.any_instance.stubs(:update!).raises(ActiveRecord::RecordInvalid)

      assert_raises(ActiveRecord::RecordInvalid) { @ownership_request.close!(@user) }
      refute_predicate @ownership_request, :closed?
    end
  end
end
