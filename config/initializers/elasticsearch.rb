require 'faraday_middleware/aws_sigv4'
require 'opensearch-dsl'

port = 9200
if Rails.env.local? && Toxiproxy.running?
  port = 22_221
  toxiproxy_listen_host = ENV.fetch("TOXIPROXY_LISTEN_HOST", "127.0.0.1")
  toxiproxy_upstream = ENV.fetch("TOXIPROXY_UPSTREAM", "127.0.0.1:9200")
  Toxiproxy.populate(
    [

      name: 'elasticsearch',
      listen: "#{toxiproxy_listen_host}:#{port}",
      upstream: toxiproxy_upstream

    ]
  )
end

options = {}

options[:url] = ENV['ELASTICSEARCH_URL'] || "http://localhost:#{port}"
options[:tracer] = SemanticLogger[OpenSearch::Client]

Searchkick.client = OpenSearch::Client.new(**options.compact) do |f|
  unless Rails.env.local?
    f.request :aws_sigv4,
      service: 'es',
      region: ENV['AWS_REGION'],
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
  end
end
