require "test_helper"

class OrganizationTest < ActiveSupport::TestCase
  should have_many(:memberships).dependent(:destroy)
  should have_many(:unconfirmed_memberships).dependent(:destroy)
  should have_many(:users).through(:memberships)
  should have_many(:rubygems).dependent(:nullify)

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
        create(:organization, handle: "mycompany")
        organization = build(:organization, handle: "MyCompany")

        refute_predicate organization, :valid?
      end

      should "be invalid with duplicate handle on update" do
        create(:organization, handle: "mycompany")
        organization = create(:organization, handle: "othercompany")
        organization.update(handle: "MyCompany")

        assert_contains organization.errors[:handle], "has already been taken"
        refute_predicate organization, :valid?
      end

      should "be invalid when handle is reserved" do
        organization = build(:organization, handle: "onboarding")

        refute_predicate organization, :valid?
        assert_contains organization.errors[:handle], "is reserved and cannot be used"
      end

      should "be invalid when handle is reserved (case insensitive)" do
        organization = build(:organization, handle: "ONBOARDING")

        refute_predicate organization, :valid?
        assert_contains organization.errors[:handle], "is reserved and cannot be used"
      end
    end
  end

  context "#flipper_id" do
    should "return org:handle" do
      organization = create(:organization)

      assert_equal "org:#{organization.handle}", organization.flipper_id
    end
  end

  context "#find_by_handle" do
    should "return organization by handle" do
      organization = create(:organization)

      assert_equal organization, Organization.find_by_handle(organization.handle)
    end

    should "return organizations by handles" do
      organization1 = create(:organization)
      organization2 = create(:organization)

      assert_equal [organization1, organization2], Organization.find_by_handle([organization1.handle, organization2.handle])
    end

    should "return nil if organization is not found" do
      assert_nil Organization.find_by_handle("nonexistent")
    end

    should "return empty array if organizations are not found" do
      assert_predicate Organization.find_by_handle(%w[nonexistent nonexistent2]), :empty?
    end
  end

  context "#find_by_handle!" do
    should "return organization by handle" do
      organization = create(:organization)

      assert_equal organization, Organization.find_by_handle!(organization.handle)
    end

    should "return organizations by handles" do
      organization1 = create(:organization)
      organization2 = create(:organization)

      assert_equal [organization1, organization2], Organization.find_by_handle!([organization1.handle, organization2.handle])
    end

    should "raise error if organization is not found" do
      assert_raises ActiveRecord::RecordNotFound do
        Organization.find_by_handle!("nonexistent")
      end
    end

    should "raise error if organizations are not found" do
      assert_raises ActiveRecord::RecordNotFound do
        Organization.find_by_handle!(%w[nonexistent nonexistent2])
      end
    end
  end
end
