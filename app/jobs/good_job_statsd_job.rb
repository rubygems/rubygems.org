class GoodJobStatsDJob < ApplicationJob
  queue_as "stats"
  self.queue_adapter = :good_job

  class Filter < GoodJob::JobsFilter
    def filtered_query(filter_params = params)
      super.group(:queue_name, :priority, "serialized_params->>'job_class'")
    end
  end

  def perform
    filter = Filter.new({})
    state_counts = filter.states

    state_staleness = state_counts.each_key.index_with do |state|
      filter.filtered_query(state:).maximum("NOW() - COALESCE(scheduled_at, created_at)")
    end

    gauge "count", state_counts
    gauge "staleness", state_staleness

    nil
  end

  def gauge(key, values)
    values.each do |state, tags|
      tags.each do |(queue, priority, job_class), value|
        StatsD.gauge("good_job.#{key}", value, tags: ["state:#{state}", "queue:#{queue}", "priority:#{priority}", "job_class:#{job_class}"])
      end
    end
  end
end
