module RubygemSearchable
  include Patterns
  extend ActiveSupport::Concern

  class SearchDownError < StandardError; end

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
      indexes :name, type: 'multi_field' do
        indexes :name, analyzer: 'rubygem'
        indexes :suggest, analyzer: 'simple'
      end
      indexes :yanked, type: 'boolean'
      indexes :summary, type: 'multi_field' do
        indexes :summary, analyzer: 'english'
        indexes :raw, analyzer: 'simple'
      end
      indexes :description, type: 'multi_field' do
        indexes :description, analyzer: 'english'
        indexes :raw, analyzer: 'simple'
      end
      indexes :downloads, type: 'integer'
      indexes :updated, type: 'date'
    end

    def self.search(query, es: false, page: 1)
      if es
        result = elastic_search(query).page(page)
        # Now we need to trigger the ES query so we can fallback if it fails
        # rather than lazy loading from the view
        result.response
        result
      else
        legacy_search(query).paginate(page: page)
      end
    rescue Faraday::ConnectionFailed => e
      Honeybadger.notify(e)
      raise SearchDownError
    rescue Elasticsearch::Transport::Transport::Error => e
      Honeybadger.notify(e)
      raise SearchDownError
    end

    def self.elastic_search(q) # rubocop:disable Metrics/MethodLength
      search_definition = Elasticsearch::DSL::Search.search do
        query do
          function_score do
            query do
              filtered do
                # Main query, search in name, summary, description
                query do
                  query_string do
                    query q
                    fields ['name^3', 'summary^1', 'description']
                    default_operator 'and'
                  end
                end

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
          versions.indexed and (name @@ to_tsquery(:query))
      SQL

      parsed_query = query.gsub(/[^a-zA-Z](?!$)/, ':* & ')
      sanitize_query = sanitize_sql_for_conditions parsed_query
      where(conditions, query: sanitize_query + ':*')
        .includes(:versions)
        .references(:versions)
        .by_downloads
    end
  end
end
