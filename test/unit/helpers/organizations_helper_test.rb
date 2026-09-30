# frozen_string_literal: true

require "test_helper"

class OrganizationsHelperTest < ActionView::TestCase
  context "invitation_expiry_tag" do
    should "show the relative time with the exact UTC time as a tooltip" do
      travel_to Time.utc(2026, 9, 30, 2, 53) do
        membership = build(:membership, :pending, invitation_expires_at: Time.utc(2026, 10, 7, 2, 53))

        html = Nokogiri::HTML5.fragment(invitation_expiry_tag(membership)).at("time")

        assert_equal "7 days", html.text
        assert_equal "October 07, 2026 02:53 UTC", html["title"]
        assert_equal "2026-10-07T02:53:00Z", html["datetime"]
      end
    end

    should "show the tooltip in UTC even when the expiry is in another zone" do
      travel_to Time.utc(2026, 9, 30, 2, 53) do
        expires_at = Time.utc(2026, 10, 7, 2, 53).in_time_zone("Australia/Melbourne")
        membership = build(:membership, :pending, invitation_expires_at: expires_at)

        html = Nokogiri::HTML5.fragment(invitation_expiry_tag(membership)).at("time")

        assert_equal "October 07, 2026 02:53 UTC", html["title"]
      end
    end
  end
end
