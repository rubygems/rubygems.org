require "test_helper"

class LinkVerificationTest < ActiveSupport::TestCase
  should belong_to :linkable

  def verification!(name, **)
    instance_variable_set "@#{name}", create(:link_verification, uri: "https://example.com/#{name}", **)
  end

  setup do
    freeze_time

    @rubygem = create(:rubygem, linkset: build(:linkset, home: nil)) # using a single rubygem to avoid creating a bunch of homepage link verifications
    verification!("unverified", linkable: @rubygem)
    verification!("expired", linkable: @rubygem, last_verified_at: 2.months.ago)
    verification!("expired_and_failed", linkable: @rubygem, last_verified_at: 2.months.ago, last_failure_at: 6.weeks.ago,
                  failures_since_last_verification: LinkVerification::MAX_FAILURES)
    verification!("failed", linkable: @rubygem, last_failure_at: 1.minute.ago,
                     failures_since_last_verification: LinkVerification::MAX_FAILURES)
    verification!("verified", linkable: @rubygem, last_verified_at: 1.week.ago)
    verification!("pending", linkable: @rubygem, last_verified_at: 25.days.ago)
    verification!("reverifying", linkable: @rubygem, last_verified_at: 25.days.ago, failures_since_last_verification: 4)
    verification!("http", linkable: @rubygem, uri: "http://example.com/http")
    verification!("invalid_uri", linkable: @rubygem, uri: " ")
  end

  context "scopes" do
    should "return verified" do
      assert_equal [@verified, @pending, @reverifying].map(&:uri).sort,
                   @rubygem.link_verifications.verified.pluck(:uri).sort
    end

    should "return unverified" do
      assert_equal [@http, @unverified, @expired, @failed, @invalid_uri, @expired_and_failed].map(&:uri).sort,
                   @rubygem.link_verifications.unverified.pluck(:uri).sort
    end

    should "return never_verified" do
      assert_equal [@unverified, @invalid_uri, @http, @failed].map(&:uri).sort,
                   @rubygem.link_verifications.never_verified.pluck(:uri).sort
    end

    should "return last_verified_before" do
      assert_equal [@expired, @expired_and_failed].map(&:uri).sort,
                   @rubygem.link_verifications.last_verified_before(1.month.ago).pluck(:uri).sort
    end

    should "return pending_verification" do
      assert_equal [@pending, @expired, @unverified].map(&:uri).sort,
                   @rubygem.link_verifications.pending_verification.pluck(:uri).sort
    end
  end

  context "#verified?" do
    should "return true for verified" do
      [@verified, @pending, @reverifying].each do |v|
        assert_predicate v, :verified?
      end
    end

    should "return false for unverified" do
      [@unverified, @expired, @failed, @http, @expired_and_failed].each do |v|
        refute_predicate v, :verified?
      end
    end
  end

  context "#unverified?" do
    should "return true for unverified" do
      [@unverified, @expired, @failed, @http, @expired_and_failed, @expired].each do |v|
        assert_predicate v, :unverified?
      end
    end

    should "return false for verified" do
      [@verified, @pending, @reverifying].each do |v|
        refute_predicate v, :unverified?
      end
    end
  end

  context "#should_verify?" do
    should "return true" do
      assert_predicate @unverified, :should_verify?
      assert_predicate @pending, :should_verify?
      assert_predicate @expired, :should_verify?
      assert_predicate @expired, :should_verify?
    end

    should "return false" do
      refute_predicate @http, :should_verify?
      refute_predicate @expired_and_failed, :should_verify?
      refute_predicate @failed, :should_verify?
      refute_predicate @invalid_uri, :should_verify?
      refute_predicate @reverifying, :should_verify?
    end
  end
end
