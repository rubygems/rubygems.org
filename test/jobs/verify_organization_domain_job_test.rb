# frozen_string_literal: true

require "test_helper"

class VerifyOrganizationDomainJobTest < ActiveJob::TestCase
  setup do
    @organization = create(:organization, handle: "arrakis", name: "Arrakis", domain: "arrakis.example.com")
  end

  # Resolv returns TXT resources whose #strings is the list of character-strings
  # making up the record's value.
  def txt(*values)
    values.map { |value| stub(strings: Array(value)) }
  end

  def stub_txt_records(*values)
    Resolv::DNS.any_instance.stubs(:getresources).returns(txt(*values))
  end

  def matching_record
    @organization.dns_txt_record_value
  end

  def perform
    VerifyOrganizationDomainJob.perform_now(organization: @organization)
  end

  context "#perform" do
    should "verify a domain publishing the expected TXT record" do
      stub_txt_records(matching_record)

      perform

      assert_predicate @organization.reload, :dns_verified?
      assert_not_nil @organization.dns_last_checked_at
    end

    should "look up TXT records at the domain apex" do
      Resolv::DNS.any_instance.expects(:getresources)
        .with("arrakis.example.com", Resolv::DNS::Resource::IN::TXT)
        .returns(txt(matching_record))

      perform

      assert_predicate @organization.reload, :dns_verified?
    end

    should "verify when the expected record sits alongside unrelated TXT records" do
      stub_txt_records("v=spf1 include:example.com ~all", matching_record, "google-site-verification=abc")

      perform

      assert_predicate @organization.reload, :dns_verified?
    end

    should "join the character-strings of a chunked TXT record before comparing" do
      chunked = [matching_record[0, 10], matching_record[10..]]
      Resolv::DNS.any_instance.stubs(:getresources).returns([stub(strings: chunked)])

      perform

      assert_predicate @organization.reload, :dns_verified?
    end

    should "not verify a domain publishing no TXT records" do
      stub_txt_records

      perform

      refute_predicate @organization.reload, :dns_verified?
      assert_not_nil @organization.dns_last_checked_at
    end

    should "not verify when the TXT record carries another organization's token" do
      other = create(:organization, handle: "caladan", name: "Caladan", domain: "arrakis.example.com")
      stub_txt_records(other.dns_txt_record_value)

      perform

      refute_predicate @organization.reload, :dns_verified?
    end

    should "not verify when the TXT record has the token but not the prefix" do
      stub_txt_records(@organization.dns_verification_token)

      perform

      refute_predicate @organization.reload, :dns_verified?
    end

    should "revoke verification when the TXT record has been removed" do
      @organization.update!(dns_verified_at: 1.day.ago, dns_last_checked_at: 1.day.ago)
      stub_txt_records("v=spf1 include:example.com ~all")

      perform

      refute_predicate @organization.reload, :dns_verified?
    end

    should "keep an existing verification when the resolver fails" do
      verified_at = 1.day.ago
      @organization.update!(dns_verified_at: verified_at, dns_last_checked_at: 1.day.ago)
      Resolv::DNS.any_instance.stubs(:getresources).raises(Resolv::ResolvError)

      perform

      assert_predicate @organization.reload, :dns_verified?
      assert_in_delta verified_at, @organization.dns_verified_at, 1.second
      assert_operator @organization.dns_last_checked_at, :>, 1.minute.ago
    end

    should "keep an existing verification when the resolver times out" do
      @organization.update!(dns_verified_at: 1.day.ago, dns_last_checked_at: 1.day.ago)
      Resolv::DNS.any_instance.stubs(:getresources).raises(Resolv::ResolvTimeout)

      perform

      assert_predicate @organization.reload, :dns_verified?
    end

    should "do nothing when the domain was cleared after the sweep enqueued the check" do
      @organization.update!(domain: nil)
      Resolv::DNS.any_instance.expects(:getresources).never

      perform

      assert_nil @organization.reload.dns_last_checked_at
    end

    should "do nothing when the domain was already checked within the check interval" do
      checked_at = 1.minute.ago
      @organization.update!(dns_last_checked_at: checked_at)
      Resolv::DNS.any_instance.expects(:getresources).never

      perform

      assert_in_delta checked_at, @organization.reload.dns_last_checked_at, 1.second
    end

    # An organization that is invalid for an unrelated reason surfaces the
    # failure from its own job, carrying that organization in the job's
    # arguments, rather than corrupting or silently skipping the check.
    should "surface an organization that is invalid for an unrelated reason" do
      @organization.update_column(:handle, "admin") # now matches Organization::Handle::RESERVED
      stub_txt_records(matching_record)

      job = VerifyOrganizationDomainJob.new(organization: @organization)

      error = assert_raises(ActiveRecord::RecordInvalid) { job.perform(organization: @organization) }
      assert_equal @organization, error.record
    end

    # The organization can be deleted between the sweep enqueuing the check and
    # the check running; that is routine, not something to report.
    should "discard the job when the organization no longer exists" do
      serialized = VerifyOrganizationDomainJob.new(organization: @organization).serialize
      @organization.destroy!
      Resolv::DNS.any_instance.expects(:getresources).never

      assert_nothing_raised { ActiveJob::Base.execute(serialized) }
    end
  end
end
