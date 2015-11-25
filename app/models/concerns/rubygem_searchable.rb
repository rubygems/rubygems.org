module RubygemSearchable
  include Patterns
  extend ActiveSupport::Concern

  class SearchDownError < StandardError; end

  included do
    include Elasticsearch::Model

    delegate :index_document, to: :__elasticsearch__
    delegate :update_document, to: :__elasticsearch__
    delegate :delete_document, to: :__elasticsearch__

    # These are not used, because we trigger the ES index from the Pusher class
    # after_commit -> { delay.index_document  }, on: :create
    # after_commit -> { delay.update_document }, on: :update
    # after_commit -> { delay.delete_document }, on: :destroy

    def as_indexed_json(_options = {})
      most_recent_version = versions.most_recent
      {
        name: name,
        yanked: !versions.any?(&:indexed?),
        summary: most_recent_version.try(:summary),
        description: most_recent_version.try(:description)
      }
    end

    settings number_of_shards: 1,
             number_of_replicas: 1,
             analysis: {
               analyzer: {
                 rubygem: {
                   type: 'pattern',
                   pattern: "[\s#{Regexp.escape(SPECIAL_CHARACTERS)}]+"
                 }
               }
             }

    mapping do
      indexes :name, analyzer: 'rubygem'
      indexes :yanked, type: 'boolean'
      indexes :summary, analyzer: 'english'
      indexes :description, analyzer: 'english'
    end

    def self.search(query, es: false, page: 1)
      if es
        result = elastic_search(query).page(page).records
        # Now we need to trigger the ES query so we can fallback if it fails
        # rather than lazy loading from the view
        result.load
        result
      else
        legacy_search(query).with_versions.paginate(page: page)
      end
    rescue Faraday::ConnectionFailed
      raise SearchDownError
    end

    def self.elastic_search(query)
      __elasticsearch__.search(
        query: {
          filtered: {
            query: {
              multi_match: {
                query: query,
                operator: 'and',
                fields: ['name^3', 'summary^1', 'description']
              }
            },
            filter: {
              bool: {
                must: {
                  term: { yanked: false }
                }
              }
            }
          }
        },
        _source: %w(name summary description)
      )
    end

    def self.legacy_search(query)
      conditions = <<-SQL
        versions.indexed and
          (UPPER(name) LIKE UPPER(:query) OR
           UPPER(TRANSLATE(name,
                           '#{SPECIAL_CHARACTERS}',
                           '#{' ' * SPECIAL_CHARACTERS.length}')
                ) LIKE UPPER(:query))
      SQL

      where(conditions, query: "%#{query.strip}%")
        .includes(:versions)
        .references(:versions)
        .by_downloads
    end
  end
end
