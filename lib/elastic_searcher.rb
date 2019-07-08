class ElasticSearcher
  def initialize(query, page: 1)
    @query  = query
    @page   = page
  end

  def search(api: false)
    @api = api
    result = Rubygem.__elasticsearch__.search(search_definition).page(@page)
    result.response # ES query is triggered here to allow fallback. avoids lazy loading done in the view
    @api ? result.map(&:_source) : [nil, result]
  rescue Faraday::ConnectionFailed, Faraday::TimeoutError, Elasticsearch::Transport::Transport::Error => e
    result = Rubygem.legacy_search(@query).page(@page)
    @api ? result : [error_msg(e), result]
  end

  def suggestions
    result = Rubygem.__elasticsearch__.search(suggestions_definition).page(@page)
    result = result.response.suggest[:completion_suggestion][0][:options]
    names = []
    result.each do |gem|
      names << gem[:_source].name
    end
    names
  rescue Faraday::ConnectionFailed, Faraday::TimeoutError, Elasticsearch::Transport::Transport::Error
    Rubygem.legacy_search(@query).page(@page)
  end

  private

  def search_definition # rubocop:disable Metrics/MethodLength
    query_str = @query
    source_array = @api ? api_source : ui_source

    Elasticsearch::DSL::Search.search do
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

    Elasticsearch::DSL::Search.search do
      suggest :completion_suggestion, prefix: query_str, completion: { field: "suggest", contexts: { yanked: false }, size: 30 }
      source "name"
    end
  end

  def error_msg(error)
    if error.is_a? Elasticsearch::Transport::Transport::Errors::BadRequest
      "Failed to parse: '#{@query}'. Falling back to legacy search."
    else
      Honeybadger.notify(error)
      "Advanced search is currently unavailable. Falling back to legacy search."
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
