# frozen_string_literal: true

require "test_helper"

class VerifyOrganizationDomainsJobTest < ActiveJob::TestCase
  setup do
    @organization = create(:organization, handle: "arrakis", name: "Arrakis", domain: "arrakis.example.com")
  end

  context "#perform" do
    should "enqueue a check for an organization that has never been checked" do
      assert_enqueued_with(job: VerifyOrganizationDomainJob, args: [organization: @organization]) do
        VerifyOrganizationDomainsJob.perform_now
      end
    end

    should "enqueue a check for an organization last checked before the check interval" do
      @organization.update!(dns_last_checked_at: (Organization::DnsVerification::CHECK_INTERVAL + 1.minute).ago)

      assert_enqueued_jobs 1, only: VerifyOrganizationDomainJob do
        VerifyOrganizationDomainsJob.perform_now
      end
    end

    should "not enqueue a check for an organization checked within the check interval" do
      @organization.update!(dns_last_checked_at: 1.minute.ago)

      assert_no_enqueued_jobs only: VerifyOrganizationDomainJob do
        VerifyOrganizationDomainsJob.perform_now
      end
    end

    should "not enqueue a check for an organization without a domain" do
      @organization.update!(domain: nil)

      assert_no_enqueued_jobs only: VerifyOrganizationDomainJob do
        VerifyOrganizationDomainsJob.perform_now
      end
    end

    should "not enqueue a check for a deleted organization" do
      @organization.update!(deleted_at: Time.current)

      assert_no_enqueued_jobs only: VerifyOrganizationDomainJob do
        VerifyOrganizationDomainsJob.perform_now
      end
    end

    should "enqueue one check per pending organization" do
      create(:organization, handle: "caladan", name: "Caladan", domain: "caladan.example.com")
      create(:organization, handle: "giediprime", name: "Giedi Prime", domain: "giedi.example.com")

      assert_enqueued_jobs 3, only: VerifyOrganizationDomainJob do
        VerifyOrganizationDomainsJob.perform_now
      end
    end

    # The sweep only enqueues, so one organization that cannot be saved (an
    # invalid handle, say) cannot stop any other organization from being
    # checked the way a single in-line sweep would.
    should "enqueue checks for every organization even when one is invalid" do
      @organization.update_column(:handle, "admin") # now matches Organization::Handle::RESERVED
      create(:organization, handle: "caladan", name: "Caladan", domain: "caladan.example.com")

      assert_enqueued_jobs 2, only: VerifyOrganizationDomainJob do
        VerifyOrganizationDomainsJob.perform_now
      end
    end

    # The sweep only enqueues, so it does no DNS work of its own and cannot be
    # held up by an unresponsive domain.
    should "not resolve anything itself" do
      Resolv::DNS.any_instance.expects(:getresources).never

      VerifyOrganizationDomainsJob.perform_now
    end
  end
end
