if Rails.env.test? || Rails.env.development?
  require 'toxiproxy'

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

url = ENV['ELASTICSEARCH_URL'] || "http://localhost:#{port}"
Elasticsearch::Model.client = Elasticsearch::Client.new(host: url)

if Rails.env.development?
  tracer = ActiveSupport::Logger.new('log/elasticsearch.log')
  tracer.level = Logger::DEBUG
  Elasticsearch::Model.client.transport.tracer = tracer
end
