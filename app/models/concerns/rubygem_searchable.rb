module RubygemSearchable
  include Patterns
  extend ActiveSupport::Concern

  class SearchDownError < StandardError; end

  included do
    include Elasticsearch::Model

    index_name "rubygems-#{Rails.env}"

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
        description: most_recent_version.try(:description),
        downloads: downloads
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
      indexes :name, type: 'multi_field' do
        indexes :name, analyzer: 'rubygem'
        indexes :suggest, analyzer: 'simple'
      end
      indexes :yanked, type: 'boolean'
      indexes :summary, analyzer: 'english'
      indexes :description, analyzer: 'english'
      indexes :downloads, type: 'integer'
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
    rescue Elasticsearch::Transport::Transport::Error
      raise SearchDownError
    end

    def self.elastic_search(q)
      search_definition = Elasticsearch::DSL::Search.search do
        query do
          function_score do
            query do
              filtered do
                # Main query, search in name, summary, description
                query do
                  multi_match do
                    query q
                    fields ['name^3', 'summary^1', 'description']
                    operator 'and'
                  end
                end

                # only return gems that are not yanked
                filter do
                  bool :yanked do
                    must do
                      term yanked: false
                    end
                  end
                end
              end
            end

            # Boost the score based on number of downloads
            functions << { field_value_factor: { field: :downloads, modifier: :log1p } }
          end
        end

        source %w(name summary description downloads)

        # Return suggestions unless there's no query from the user
        unless q.blank?
          suggest :suggest_name, text: q, term: { field: 'name.suggest', suggest_mode: 'always' }
        end
      end
      __elasticsearch__.search(search_definition)
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
