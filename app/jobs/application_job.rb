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

  concerning "FeatureFlagging" do
    included do
      def ld_context
        LaunchDarkly::LDContext.with_key(self.class.name, "active_job")
      end

      def ld_variation(key:, default:)
        Rails.configuration.launch_darkly_client.variation(
          key, ld_context, default
        )
      end
    end

    class_methods do
      def good_job_concurrency_perform_limit(default: nil)
        proc do
          ld_variation(key: "good_job.concurrency.perform_limit", default:)
        end
      end

      def good_job_concurrency_enqueue_limit(default: nil)
        proc do
          ld_variation(key: "good_job.concurrency.enqueue_limit", default:)
        end
      end
    end
  end
end
