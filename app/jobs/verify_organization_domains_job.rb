# frozen_string_literal: true

# Enqueues a domain check for every organization whose claimed domain is due
# for one. The check itself runs per organization in
# VerifyOrganizationDomainJob, so an organization that fails for an unrelated
# reason fails only its own job and is reported with its own identity.
#
# Scheduled via GoodJob cron (config/initializers/good_job.rb).
class VerifyOrganizationDomainsJob < ApplicationJob
  queue_as "stats"

  include GoodJob::ActiveJobExtensions::Concurrency

  # One sweep at a time; overlapping runs would enqueue the same organizations.
  good_job_control_concurrency_with(
    enqueue_limit: 1,
    perform_limit: 1,
    key: name
  )

  def perform
    enqueued = 0

    Organization.pending_dns_verification.find_each do |organization|
      VerifyOrganizationDomainJob.perform_later(organization:)
      enqueued += 1
    end

    StatsD.gauge("organization_domains.verify.enqueued", enqueued)
  end
end
