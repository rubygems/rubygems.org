require "test_helper"

class Organization::ReservedHandlesTest < ActiveSupport::TestCase
  context ".reserved?" do
    should "return true for reserved handles" do
      %w[onboarding api admin dashboard profile settings].each do |handle|
        assert Organization::Handle.reserved?(handle), "Expected '#{handle}' to be reserved"
      end
    end

    should "be case insensitive" do
      assert Organization::Handle.reserved?("onboarding")
      assert Organization::Handle.reserved?("ONBOARDING")
      assert Organization::Handle.reserved?("OnBoArDiNg")
    end

    should "work with symbols" do
      assert Organization::Handle.reserved?(:onboarding)
      assert Organization::Handle.reserved?(:API)
    end

    should "return false for non-reserved handles" do
      %w[mycompany validname github microsoft].each do |handle|
        refute Organization::Handle.reserved?(handle), "Expected '#{handle}' to not be reserved"
      end
    end

    should "include common route conflicts" do
      # Test a subset of important reserved handles to ensure they're included
      expected_reserved = %w[
        onboarding new edit create update destroy index show
        api admin dashboard profile settings
        user users organization organizations
        gem gems search stats
      ]

      expected_reserved.each do |handle|
        assert_includes Organization::Handle::RESERVED, handle, "Expected '#{handle}' to be in RESERVED list"
      end
    end
  end
end
