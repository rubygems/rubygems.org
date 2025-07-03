class GoodJobStatsDJob < ApplicationJob
  queue_as "stats"

  class Filter < GoodJob::JobsFilter
    def filtered_query(filter_params = params)
      super.then do |rel|
        rel.group(:queue_name, :priority, Arel.sql("#{rel.quoted_table_name}.serialized_params->>'job_class'"))
      end
    end
  end

  def perform
    filter = Filter.new({})

    state_counts = filter.states
    gauge "count", state_counts

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
