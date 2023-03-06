class FastlyLogProcessorJob < ApplicationJob
  queue_as :default
  queue_with_priority PRIORITIES.fetch(:stats)

  def perform(bucket:, key:)
    FastlyLogProcessor.new(bucket, key).perform
  end
end
