# frozen_string_literal: true

# Runs the DNS check for one OrganizationDomain in the background. One owner
# click records at most one check: DNS failures are recorded as the check's
# other_error outcome, so the job itself is never retried.
class OrganizationDomainVerificationJob < ApplicationJob
  queue_as :default

  include GoodJob::ActiveJobExtensions::Concurrency

  # At most one queued and one running job per domain, so a second Verify click
  # while one is pending does not enqueue a duplicate.
  good_job_control_concurrency_with(
    enqueue_limit: 1,
    perform_limit: 1,
    key: -> { "#{self.class.name}-#{arguments.first}" }
  )

  # Replaces ApplicationJob's retry_on StandardError: never re-run the DNS work.
  # Declared before the more specific handler below, which takes precedence.
  discard_on StandardError do |job, error|
    OrganizationDomain.where(id: job.arguments.first).update_all(check_queued_at: nil)
    Rails.error.report(error, handled: false)
  end

  # The domain was removed before or during the run: nothing to record or clear.
  discard_on ActiveRecord::RecordNotFound, OrganizationDomain::DnsCheck::DeletedDomain

  # Takes the id (not the record) so a removed domain is a quiet no-op rather
  # than a deserialization error.
  def perform(domain_id)
    OrganizationDomain.find(domain_id).verify!
  end
end
