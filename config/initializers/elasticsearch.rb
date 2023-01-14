require 'faraday_middleware/aws_sigv4'

port = 9200
if (Rails.env.test? || Rails.env.development?) && Toxiproxy.running?
  port = 22_221
  Toxiproxy.populate(
    [
      {
        name: 'elasticsearch',
        listen: "127.0.0.1:#{port}",
        upstream: '127.0.0.1:9200'
      }
    ]
  )
end

options = {}

options[:url] = ENV['ELASTICSEARCH_URL'] || "http://localhost:#{port}"

if Rails.env.development?
  logger = ActiveSupport::Logger.new('log/elasticsearch.log')
  logger.level = Logger::DEBUG
  options[:tracer] = logger
end

Searchkick.client = OpenSearch::Client.new(**options.compact) do |f|
  if Rails.env.staging? || Rails.env.production?
    f.request :aws_sigv4,
      service: 'es',
      region: ENV['AWS_REGION'],
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
  end
end
