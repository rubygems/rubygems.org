ActiveSupport::Notifications.subscribe(/process_action.action_controller/) do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  event.payload[:format] = event.payload[:format] || 'all'
  event.payload[:format] = 'all' if event.payload[:format] == '*/*'
  status = event.payload[:status]
  ActiveSupport::Notifications.instrument :performance,
    event.payload.merge(statsd_method: :measure,
                        measurement: 'total_duration',
                        value: event.duration)
  ActiveSupport::Notifications.instrument :performance,
    event.payload.merge(statsd_method: :measure,
                        measurement: 'db_time',
                        value: event.payload[:db_runtime])
  ActiveSupport::Notifications.instrument :performance,
    event.payload.merge(statsd_method: :measure,
                        measurement: 'view_time',
                        value: event.payload[:view_runtime])
  ActiveSupport::Notifications.instrument :performance,
    event.payload.merge(measurement: "status.#{status}")
end

ActiveSupport::Notifications.subscribe(/performance/) do |name, _, _, _, payload|
  method = payload[:statsd_method] || :increment
  measurement = payload[:measurement]
  value = payload[:value]
  key_name = "rails.#{name}.#{measurement}"
  StatsD.__send__ method.to_s,
    key_name,
    (value || 1),
    tags: ["controller:#{payload[:controller]}",
           "action:#{payload[:action]}",
           "format:#{payload[:format]}"]
end
