class FastlyLogProcessorJob < ApplicationJob
  queue_as :default
  queue_with_priority PRIORITIES.fetch(:stats)
  self.queue_adapter = :good_job

  def perform(bucket:, key:)
    FastlyLogProcessor.new(bucket, key).perform
  end
end
