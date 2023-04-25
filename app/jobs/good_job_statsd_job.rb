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
    now = Time.now.utc

    state_counts = filter.states
    gauge "count", state_counts

    if ld_variation(key: "good_job.GoodJobStatsDJob.measure_staleness", default: true)
      state_staleness = state_counts.each_key.index_with do |state|
        case state
        when "scheduled", "queued" # not started jobs don't have discrete execution entry yet
          columns = %w[executions_good_jobs.scheduled_at executions_good_jobs.created_at]
          relation = :executions
        when "retried", "running", "succeeded", "discarded"
          columns = %w[good_job_executions.scheduled_at good_job_executions.created_at]
          relation = :discrete_executions
        else raise "unknown GoodJob state '#{state}'"
        end

        staleness(now, filter.filtered_query(state:), columns, relation)
      end
      gauge "staleness", state_staleness
    end

    if ld_variation(key: "good_job.GoodJobStatsDJob.measure_latest_execution", default: true)
      state_latest_execution = state_counts.each_key.index_with do |state|
        columns = %w[good_job_executions.performed_at good_job_executions.finished_at good_job_executions.scheduled_at good_job_executions.created_at]
        staleness(now, filter.filtered_query(state:), columns, :discrete_executions)
      end
      gauge "latest_execution", state_latest_execution
    end

    nil
  end

  def staleness(now, filtered_query, columns, joined_relation)
    filtered_query.joins(joined_relation).then do |rel|
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
