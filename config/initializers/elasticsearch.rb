# frozen_string_literal: true

require 'faraday_middleware/aws_sigv4'
require 'opensearch-dsl'

options = {}

options[:url] = ENV['ELASTICSEARCH_URL'] || 'http://localhost:9200'
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
