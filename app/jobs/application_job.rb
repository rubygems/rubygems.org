class ApplicationJob < ActiveJob::Base
  # Default to retrying errors a few times, so we don't get an alert for
  # spurious errors
  retry_on StandardError, wait: :exponentially_longer, attempts: 5

  # Automatically retry jobs that encountered a deadlock
  retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError
end
