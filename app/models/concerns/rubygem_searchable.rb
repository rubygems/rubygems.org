module RubygemSearchable
  include Patterns
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model

    index_name "rubygems-#{Rails.env}"

    delegate :index_document, to: :__elasticsearch__
    delegate :update_document, to: :__elasticsearch__

    def as_indexed_json(_options = {})
      most_recent_version = versions.most_recent
      {
        name:                  name,
        yanked:                !versions.any?(&:indexed?),
        summary:               most_recent_version.try(:summary),
        description:           most_recent_version.try(:description),
        downloads:             downloads,
        latest_version_number: most_recent_version.try(:number),
        updated:               updated_at
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
      indexes :name, type: 'text' do
        indexes :name, analyzer: 'rubygem'
        indexes :suggest, analyzer: 'simple'
      end
      indexes :yanked, type: 'boolean'
      indexes :summary, type: 'text' do
        indexes :summary, analyzer: 'english'
        indexes :raw, analyzer: 'simple'
      end
      indexes :description, type: 'text' do
        indexes :description, analyzer: 'english'
        indexes :raw, analyzer: 'simple'
      end
      indexes :downloads, type: 'integer'
      indexes :updated, type: 'date'
    end

    def self.search(query, es: false, page: 1)
      return [nil, legacy_search(query).page(page)] unless es
      result = elastic_search(query).page(page)
      # Now we need to trigger the ES query so we can fallback if it fails
      # rather than lazy loading from the view
      result.response
      [nil, result]
    rescue Faraday::ConnectionFailed, Faraday::TimeoutError, Elasticsearch::Transport::Transport::Error => e
      msg = error_msg query, e
      [msg, legacy_search(query).page(page)]
    end

    def self.elastic_search(q) # rubocop:disable Metrics/MethodLength
      search_definition = Elasticsearch::DSL::Search.search do
        query do
          function_score do
            query do
              bool do
                # Main query, search in name, summary, description
                should do
                  query_string do
                    query q
                    fields ['name^5', 'summary^3', 'description']
                    default_operator 'and'
                  end
                end
                minimum_should_match 1
                # only return gems that are not yanked
                filter { term yanked: false }
              end
            end

            # Boost the score based on number of downloads
            functions << { field_value_factor: { field: :downloads, modifier: :log1p } }
          end
        end

        aggregation :matched_field do
          filters do
            filters name: { terms: { name: [q] } },
                    summary: { terms: { 'summary.raw' => [q] } },
                    description: { terms: { 'description.raw' => [q] } }
          end
        end

        aggregation :date_range do
          date_range do
            field  'updated'
            ranges [{ from: 'now-7d/d', to: 'now' }, { from: 'now-30d/d', to: 'now' }]
          end
        end

        source %w(name summary description downloads latest_version_number)

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
        .includes(:latest_version, :gem_download)
        .references(:versions)
        .by_downloads
    end

    def self.error_msg(query, error)
      if error.is_a? Elasticsearch::Transport::Transport::Errors::BadRequest
        "Failed to parse: '#{query}'. Falling back to legacy search."
      else
        Honeybadger.notify(error)
        "Advanced search is currently unavailable. Falling back to legacy search."
      end
    end
  end
end
