# TODO: add feature to statsd-instrument for default tags
class StatsD::Instrument::Metric
  def self.normalize_tags(tags)
    tags ||= []
    tags = tags.map { |k, v| k.to_s + ":".freeze + v.to_s } if tags.is_a?(Hash)
    tags.map { |tag| tag.tr('|,'.freeze, ''.freeze) }
    tags << "env:#{Rails.env}" # Added to allow default env tag on all metrics
  end
end

ActiveSupport::Notifications.subscribe(/process_action.action_controller/) do |event|
  event.payload[:format] = event.payload[:format] || 'all'
  event.payload[:format] = 'all' if event.payload[:format] == '*/*'
  status = event.payload[:status]
  statsd_measure_performance :performance,
    event.payload.merge(statsd_method: :measure,
                        measurement: 'total_duration',
                        value: event.duration)
  statsd_measure_performance :performance,
    event.payload.merge(statsd_method: :measure,
                        measurement: 'db_time',
                        value: event.payload[:db_runtime])
  statsd_measure_performance :performance,
    event.payload.merge(statsd_method: :measure,
                        measurement: 'view_time',
                        value: event.payload[:view_runtime])
  statsd_measure_performance :performance,
    event.payload.merge(statsd_method: :histogram,
                        measurement: "allocations",
                        value: event.allocations)
  statsd_measure_performance :performance,
    event.payload.merge(measurement: "status.#{status}")
end

ActiveSupport::Notifications.subscribe(/\.active_job/) do |event|
  job = event.payload[:job]
  adapter = event.payload[:adapter]

  statsd_tags = job.statsd_tags.merge(
    adapter: adapter.class.name,
    error: event.payload[:error]&.class&.name,
    exception: event.payload.dig(:exception, 0)
  )

  statsd_measure_performance event.name,
    event.payload.merge(statsd_method: :measure,
                        measurement: 'total_duration',
                        value: event.duration,
                        statsd_tags:)
  statsd_measure_performance event.name,
    event.payload.merge(statsd_method: :histogram,
                        measurement: "allocations",
                        value: event.allocations,
                        statsd_tags:)
  statsd_measure_performance event.name,
    event.payload.merge(
      measurement: statsd_tags[:exception] ? "failure" : "success",
      statsd_tags:
    )
end

def statsd_measure_performance(name, payload)
  method = payload[:statsd_method] || :increment
  measurement = payload[:measurement]
  value = payload[:value] || 1
  key_name = "rails.#{name}.#{measurement}"
  StatsD.__send__ method,
    key_name,
    value,
    tags: payload.slice(:controller, :action, :format).merge(payload.fetch(:statsd_tags, {})).compact
end

ActiveSupport::Notifications.subscribe(/performance/) do |name, _, _, _, payload|
  statsd_measure_performance(name, payload)
end

Rails.application.config.after_initialize do
  ActiveSupport.on_load(:active_job) { include JobTags }
end
