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
    now = Time.now.utc

    state_staleness = state_counts.each_key.index_with do |state|
      staleness(
        now,
        filter.filtered_query(state:),
        %w[executions_good_jobs.scheduled_at executions_good_jobs.created_at]
      )
    end

    state_latest_execution = state_counts.each_key.index_with do |state|
      staleness(
        now,
        filter.filtered_query(state:),
        %w[executions_good_jobs.performed_at executions_good_jobs.finished_at executions_good_jobs.scheduled_at executions_good_jobs.created_at]
      )
    end

    gauge "count", state_counts
    gauge "staleness", state_staleness
    gauge "latest_execution", state_latest_execution

    nil
  end

  def staleness(now, filtered_query, columns)
    filtered_query.joins(:executions).then do |rel|
      rel.pluck(
        *rel.group_values,
        Arel::Nodes::Max.new(
          [Arel::Nodes.build_quoted(now, rel.arel_table[:created_at]) -
            rel.arel_table.coalesce(*rel.send(:arel_columns, columns))]
        )
      )
        .to_h { |*a, v| [a, v] }
    end
  end

  def gauge(key, values)
    values.each do |state, tags|
      tags.each do |(queue, priority, job_class), value|
        StatsD.gauge("good_job.#{key}", value, tags: ["state:#{state}", "queue:#{queue}", "priority:#{priority}", "job_class:#{job_class}"])
      end
    end
  end
end
