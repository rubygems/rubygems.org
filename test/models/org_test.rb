require "test_helper"

class OrgTest < ActiveSupport::TestCase
  should have_many(:memberships).dependent(:destroy)
  should have_many(:unconfirmed_memberships).dependent(:destroy)
  should have_many(:users).through(:memberships)

  # Waiting for Ownerships to be made polymorphic
  #
  # should have_many(:ownerships).dependent(:destroy)
  # should have_many(:unconfirmed_ownerships).dependent(:destroy)
  # should have_many(:rubygems).through(:ownerships)

  context "validations" do
    context "handle" do
      should allow_value("CapsLOCK").for(:handle)
      should_not allow_value(nil).for(:handle)
      should_not allow_value("1abcde").for(:handle)
      should_not allow_value("abc^%def").for(:handle)
      should_not allow_value("abc\n<script>bad").for(:handle)

      should "be between 2 and 40 characters" do
        org = build(:org, handle: "a")

        refute_predicate org, :valid?
        assert_contains org.errors[:handle], "is too short (minimum is 2 characters)"

        org.handle = "a" * 41

        refute_predicate org, :valid?
        assert_contains org.errors[:handle], "is too long (maximum is 40 characters)"

        org.handle = "abcdef"
        org.valid?

        assert_nil org.errors[:handle].first
      end

      should "be invalid when an empty string" do
        org = build(:org, handle: "")

        refute_predicate org, :valid?
      end

      should "be invalid when nil" do
        refute_predicate build(:org, handle: nil), :valid?
      end

      should "be invalid with duplicate handle on create" do
        create(:org, handle: "test")
        org = build(:org, handle: "Test")

        refute_predicate org, :valid?
      end

      should "be invalid with duplicate handle on update" do
        create(:org, handle: "test")
        org = create(:org, handle: "test2")
        org.update(handle: "Test")

        assert_contains org.errors[:handle], "has already been taken"
        refute_predicate org, :valid?
      end

      should "be invalid if user has handle already" do
        create(:user, handle: "test")
        org = build(:org, handle: "Test")

        refute_predicate org, :valid?
        assert_contains org.errors[:handle], "has already been taken"
      end
    end
  end
end
