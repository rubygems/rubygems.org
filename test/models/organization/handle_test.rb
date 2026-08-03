# frozen_string_literal: true

require "test_helper"

class Organization::ReservedHandlesTest < ActiveSupport::TestCase
  context ".normalize" do
    should "downcase and strip separators" do
      assert_equal "signin", Organization::Handle.normalize("Sign_In")
      assert_equal "rubygems", Organization::Handle.normalize("Ruby-Gems")
      assert_equal "rubygems", Organization::Handle.normalize("ruby_gems")
    end

    should "handle nil and symbols" do
      assert_equal "", Organization::Handle.normalize(nil)
      assert_equal "api", Organization::Handle.normalize(:API)
    end
  end

  context ".reserved?" do
    should "be case insensitive" do
      assert Organization::Handle.reserved?("onboarding")
      assert Organization::Handle.reserved?("ONBOARDING")
      assert Organization::Handle.reserved?("OnBoArDiNg")
    end

    should "work with symbols" do
      assert Organization::Handle.reserved?(:onboarding)
      assert Organization::Handle.reserved?(:API)
    end

    should "ignore separators, so one spelling covers all variations" do
      assert Organization::Handle.reserved?("sign_in")
      assert Organization::Handle.reserved?("sign-in")
      assert Organization::Handle.reserved?("signin")

      assert Organization::Handle.reserved?("rubygems")
      assert Organization::Handle.reserved?("ruby-gems")
      assert Organization::Handle.reserved?("RUBY_GEMS")
    end

    # TODO: BRIAN: I'm not sure on how to handle the prefix problem as of yet
    should "not treat a reserved name as a prefix or substring match" do
      refute Organization::Handle.reserved?("apiary")
      refute Organization::Handle.reserved?("myapi")
      refute Organization::Handle.reserved?("rubygemsfan")
    end

    should "include common route conflicts" do
      expected_reserved = %w[
        new edit create update destroy index show
        onboarding members users invitation invitations
        api admin dashboard profile settings users teams
        gems stats
      ]

      expected_reserved.each do |handle|
        assert_includes Organization::Handle::RESERVED, handle, "Expected '#{handle}' to be in RESERVED list"
      end
    end

    should "reserve every top-level path segment used in the app's routes" do
      segments = Rails.application.routes.routes.filter_map do |route|
        spec = route.path.spec.to_s
        next if spec.start_with?("/:", "/*")

        spec.split("/").compact_blank.first
      end

      segments.uniq.each do |segment|
        # Skip segments that can't be typed as a handle
        next unless segment.match?(Patterns::HANDLE_PATTERN)
        next if segment.length < 2 || segment.length > 40
        next if segment == "rails" # This is already taken as an Organization handle

        assert Organization::Handle.reserved?(segment),
          "Route segment '/#{segment}' is not a reserved Organization::Handle"
      end
    end
  end

  context "the reserved list" do
    should "contain only handles that are otherwise valid" do
      Organization::Handle::RESERVED.each do |handle|
        assert_match Patterns::HANDLE_PATTERN, handle, "Reserved handle '#{handle}' is not a valid handle format"
        assert_operator handle.length, :>=, 2, "Reserved handle '#{handle}' is shorter than the minimum handle length"
        assert_operator handle.length, :<=, 40, "Reserved handle '#{handle}' is longer than the maximum handle length"
      end
    end

    should "be lowercase" do
      Organization::Handle::RESERVED.each do |handle|
        assert_equal handle.downcase, handle, "Reserved handle '#{handle}' should be lowercase"
      end
    end

    should "not contain entries that are redundant once normalized" do
      duplicates = Organization::Handle::RESERVED
        .group_by { Organization::Handle.normalize(it) }
        .select { |_normalized, handles| handles.size > 1 }

      assert_empty duplicates, "Redundant reserved entries (identical once normalized): #{duplicates.values.inspect}"
    end
  end
end
