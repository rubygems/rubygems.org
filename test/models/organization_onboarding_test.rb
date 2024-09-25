require "test_helper"

class OrganizationOnboardingTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @organization = create(:organization)
    @membership = create(:membership)

    @onboarding = create(:organization_onboarding)
  end

  context "validations" do
    setup do
      @onboarding = OrganizationOnboarding.new
    end

    should "require a onboarded by user" do
      assert_predicate @onboarding, :invalid?
      assert_equal ["can't be blank"], @onboarding.errors[:created_by]
    end

    context "when the user does not have the required gem roles" do
      setup do
        @rubygem = create(:rubygem)
        @ownership = create(:ownership, rubygem: @rubygem, role: :maintainer)
        @onboarding = build(:organization_onboarding, ownership: @ownership, rubygems: [@rubygem.id])
      end

      should "be invalid" do
        assert_predicate @onboarding, :invalid?
      end

      should "add an error to the rubygems attribute" do
        @onboarding.valid?

        assert_equal ["User does not own gem #{@rubygem.name}"], @onboarding.errors[:rubygems]
      end
    end

    context "when the user specifies a gem they do not own" do
      setup do
        @rubygem = create(:rubygem)
        @onboarding.rubygems = [@rubygem.id]
      end

      should "be invalid" do
        assert_predicate @onboarding, :invalid?
      end

      should "add an error to the rubygems attribute" do
        @onboarding.valid?

        assert_equal ["User does not have owner permissions for gem: #{@rubygem.id}"], @onboarding.errors[:rubygems]
      end
    end
  end

  context "#onboard!" do
    setup do
      @onboarding.onboard!
    end

    should "mark the onboarding as completed" do
      assert_predicate @onboarding, :completed?
    end

    # context "when onboarding encounters an error" do
    #   should "mark the onboarding as failed" do
    #     assert_predicate @onboarding, :failed?
    #   end

    #   should "record the error message" do
    #     assert_equal "actor id error", @onboarding.error
    #   end
    # end

    context "when the onboarding is already completed" do
      setup do
        @onboarding = create(:organization_onboarding, :completed)
      end

      should "raise an ActiveRecord::RecordInvalid error" do
        assert_raises StandardError, "onboard has already been completed" do
          @onboarding.onboard!
        end
      end
    end
  end
end
