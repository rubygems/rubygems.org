class FastlyPurgeJob < ApplicationJob
  queue_as :default
  self.queue_adapter = :good_job

  def perform(path:, soft:)
    Fastly.purge({ path:, soft: })
  end
end
