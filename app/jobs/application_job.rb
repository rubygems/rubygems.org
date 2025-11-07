class ApplicationJob < ActiveJob::Base
  include SemanticLogger::Loggable

  PRIORITIES = ActiveSupport::OrderedOptions[{
    push: 1,
    download: 2,
    web_hook: 3,
    profile_deletion: 3,
    stats: 4
  }].freeze

  # Default to retrying errors a few times, so we don't get an alert for
  # spurious errors
  retry_on StandardError, wait: :polynomially_longer, attempts: 5

  # Automatically retry jobs that encountered a deadlock
  retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError

  after_discard do |job, exception|
    tags = job.statsd_tags.merge(
      exception: exception.class.name,
      adapter: job.class.queue_adapter.class.name
    )
    StatsD.increment("good_job.discarded", tags: tags)
  end
end
