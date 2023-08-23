class ElasticSearcher
  CONNECTION_ERRORS = [
    Faraday::ConnectionFailed,
    Faraday::TimeoutError,
    Searchkick::Error,
    OpenSearch::Transport::Transport::Error,
    Errno::ECONNRESET,
    HTTPClient::KeepAliveDisconnected
  ].freeze

  SearchNotAvailableError = Class.new(StandardError)
  InvalidQueryError = Class.new(StandardError)

  def initialize(query, page: 1)
    @query  = query
    @page   = page
  end

  def search
    result = Rubygem.searchkick_search(
      body: search_definition.to_hash,
      page: @page,
      per_page: Kaminari.config.default_per_page,
      load: false
    )
    result.response # ES query is triggered here to allow fallback. avoids lazy loading done in the view
    [nil, result]
  rescue StandardError => e
    [error_msg(e), nil]
  end

  def api_search
    result = Rubygem.searchkick_search(body: search_definition(for_api: true).to_hash, page: @page, per_page: Kaminari.config.default_per_page,
load: false)
    result.response["hits"]["hits"].pluck("_source")
  rescue Searchkick::InvalidQueryError
    raise InvalidQueryError
  rescue *CONNECTION_ERRORS
    raise SearchNotAvailableError
  end

  def suggestions
    result = Rubygem.searchkick_search(body: suggestions_definition.to_hash, page: @page, per_page: Kaminari.config.default_per_page, load: false)
    result = result.response["suggest"]["completion_suggestion"][0]["options"]
    result.map { |gem| gem["_source"]["name"] }
  rescue *CONNECTION_ERRORS
    Array(nil)
  end

  private

  def search_definition(for_api: false) # rubocop:disable Metrics/MethodLength
    query_str = @query
    source_array = for_api ? api_source : ui_source

    OpenSearch::DSL::Search.search do
      query do
        function_score do
          query do
            bool do
              # Main query, search in name, summary, description
              should do
                query_string do
                  query query_str
                  fields ["name^5", "summary^2", "description"]
                  default_operator "and"
                end
              end

              should do
                prefix "name.unanalyzed" do
                  value query_str
                  boost 7
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
          filters name: { terms: { name: [query_str] } },
                  summary: { terms: { "summary.raw" => [query_str] } },
                  description: { terms: { "description.raw" => [query_str] } }
        end
      end

      aggregation :date_range do
        date_range do
          field  "updated"
          ranges [{ from: "now-7d/d", to: "now" }, { from: "now-30d/d", to: "now" }]
        end
      end

      source source_array
      # Return suggestions unless there's no query from the user
      suggest :suggest_name, text: query_str, term: { field: "name.suggest", suggest_mode: "always" } if query_str.present?
    end
  end

  def suggestions_definition
    query_str = @query

    OpenSearch::DSL::Search.search do
      suggest :completion_suggestion, prefix: query_str, completion: { field: "suggest", contexts: { yanked: false }, size: 30 }
      source "name"
    end
  end

  def error_msg(error)
    if error.is_a? Searchkick::InvalidQueryError
      "Failed to parse search term: '#{@query}'."
    else
      Rails.error.report(error, handled: true)
      "Search is currently unavailable. Please try again later."
    end
  end

  def api_source
    %w[name
       downloads
       version
       version_downloads
       platform
       authors
       info
       licenses
       metadata
       sha
       project_uri
       gem_uri
       homepage_uri
       wiki_uri
       documentation_uri
       mailing_list_uri
       funding_uri
       source_code_uri
       bug_tracker_uri
       changelog_uri]
  end

  def ui_source
    %w[name
       summary
       description
       downloads
       version]
  end
end
