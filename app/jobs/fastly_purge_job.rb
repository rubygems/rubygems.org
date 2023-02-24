class FastlyPurgeJob < ApplicationJob
  queue_as :default

  def perform(path:, soft:)
    Fastly.purge({ path:, soft: })
  end
end
