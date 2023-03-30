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

options[:tracer] = SemanticLogger[OpenSearch::Client]

Searchkick.client = OpenSearch::Client.new(**options.compact) do |f|
  unless Rails.env.development? || Rails.env.test?
    f.request :aws_sigv4,
      service: 'es',
      region: ENV['AWS_REGION'],
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
  end
end
