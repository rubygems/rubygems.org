require "test_helper"

class OrganizationTest < ActiveSupport::TestCase
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
        organization = build(:organization, handle: "a")

        refute_predicate organization, :valid?
        assert_contains organization.errors[:handle], "is too short (minimum is 2 characters)"

        organization.handle = "a" * 41

        refute_predicate organization, :valid?
        assert_contains organization.errors[:handle], "is too long (maximum is 40 characters)"

        organization.handle = "abcdef"
        organization.valid?

        assert_nil organization.errors[:handle].first
      end

      should "be invalid when an empty string" do
        organization = build(:organization, handle: "")

        refute_predicate organization, :valid?
      end

      should "be invalid when nil" do
        refute_predicate build(:organization, handle: nil), :valid?
      end

      should "be invalid with duplicate handle on create" do
        create(:organization, handle: "test")
        organization = build(:organization, handle: "Test")

        refute_predicate organization, :valid?
      end

      should "be invalid with duplicate handle on update" do
        create(:organization, handle: "test")
        organization = create(:organization, handle: "test2")
        organization.update(handle: "Test")

        assert_contains organization.errors[:handle], "has already been taken"
        refute_predicate organization, :valid?
      end

      should "be invalid if user has handle already" do
        create(:user, handle: "test")
        organization = build(:organization, handle: "Test")

        refute_predicate organization, :valid?
        assert_contains organization.errors[:handle], "has already been taken"
      end
    end
  end
end
