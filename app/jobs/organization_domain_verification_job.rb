# frozen_string_literal: true

# Runs the DNS check for one OrganizationDomain in the background. One owner
# click records at most one check. Every error is caught inside perform and
# recorded as a failed check, so the job always completes and is never retried
# by ApplicationJob. GoodJob's own concurrency retry (raised before perform runs)
# is left untouched.
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

  # Takes the id (not the record) so a removed domain is a quiet no-op rather
  # than a deserialization error.
  def perform(domain_id)
    domain = OrganizationDomain.find_by(id: domain_id)
    return if domain.nil?

    domain.verify!
  rescue OrganizationDomain::DeletedDomain
    nil # Removed during the check: nothing to record.
  rescue StandardError => e
    Rails.error.report(e, handled: true)
    record_failure(domain, e)
  end

  private

  def record_failure(domain, error)
    return if domain.nil?

    message = "#{error.class}: #{error.message}".truncate(OrganizationDomainCheck::MAX_MESSAGE_LENGTH)
    domain.record_check!(outcome: "other_error", message:)
  rescue ActiveRecord::RecordNotFound
    nil # Removed meanwhile: nothing to record.
  rescue StandardError => e
    # Recording failed too: report it and make sure the row doesn't stay "Checking".
    Rails.error.report(e, handled: true)
    OrganizationDomain.where(id: domain.id).update_all(check_queued_at: nil)
  end
end
