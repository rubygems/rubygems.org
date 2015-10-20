require 'uri'
require 'typhoeus'
require 'typhoeus/adapters/faraday'

if Rails.env.test? || Rails.env.development?
  port = Toxiproxy.running? ? 22_221 : 9200
  if Toxiproxy.running?
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
end

uri = URI(ENV['ELASTICSEARCH_URL'] || "http://localhost:#{port || 9200}")

transport = Elasticsearch::Transport::Transport::HTTP::Faraday.new(hosts: [{ host: uri.host, port: uri.port }]) do |config|
  config.adapter :typhoeus
end

Elasticsearch::Model.client = Elasticsearch::Client.new(transport: transport, reload_on_failure: true)

if Rails.env.development?
  tracer = ActiveSupport::Logger.new('log/elasticsearch.log')
  tracer.level = Logger::DEBUG
  Elasticsearch::Model.client.transport.tracer = tracer
end
