# frozen_string_literal: true

class CacheExposureMailDeliveryJob < ActionMailer::MailDeliveryJob
  include GoodJob::ActiveJobExtensions::Concurrency

  good_job_control_concurrency_with(
    # Cap concurrent sends fleet-wide so the bulk incident notices' per-mail
    # record_delivery writes can't overload the DB, however far the
    # within_24_hours fleet is scaled for throughput. No enqueue_limit: every
    # notice must still be enqueued, only concurrent delivery is capped. 5 matches
    # the fleet's default thread ceiling (1 pod x GOOD_JOB_MAX_THREADS=5), so it
    # drains the backlog within the 24h target without scaling.
    perform_limit: 5,
    key: name
  )
end
