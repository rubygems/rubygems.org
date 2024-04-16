module RubygemSearchable
  extend ActiveSupport::Concern

  included do
    searchkick index_name: Gemcutter::SEARCH_INDEX_NAME,
      callbacks: false,
      settings: {
        number_of_shards: 1,
        number_of_replicas: Gemcutter::SEARCH_NUM_REPLICAS,
        analysis: {
          analyzer: {
            rubygem: {
              type: "pattern",
              pattern: "[\s#{Regexp.escape(Patterns::SPECIAL_CHARACTERS)}]+"
            }
          }
        }
      },
      mappings:  {
        properties: {
          name: { type: "text", analyzer: "rubygem",
                  fields: { suggest: { analyzer: "simple", type: "text" }, unanalyzed: { type: "keyword", index: "true" } } },
          summary: { type: "text", analyzer: "english", fields: { raw: { analyzer: "simple", type: "text" } } },
          description: { type: "text", analyzer: "english", fields: { raw: { analyzer: "simple", type: "text" } } },
          suggest: { type: "completion", contexts: { name: "yanked", type: "category" } },
          yanked: { type: "boolean" },
          downloads: { type: "integer" },
          updated: { type: "date" }
        }
      }

    def search_data # rubocop:disable Metrics/MethodLength
      if (latest_version = most_recent_version)
        deps = latest_version.dependencies.to_a
        versioned_links = links(latest_version)
      end

      {
        name:              name,
        downloads:         downloads,
        version:           latest_version&.number,
        version_downloads: latest_version&.downloads_count,
        platform:          latest_version&.platform,
        authors:           latest_version&.authors,
        info:              latest_version&.info,
        licenses:          latest_version&.licenses,
        metadata:          latest_version&.metadata,
        sha:               latest_version&.sha256_hex,
        project_uri:       "#{Gemcutter::PROTOCOL}://#{Gemcutter::HOST}/gems/#{name}",
        gem_uri:           "#{Gemcutter::PROTOCOL}://#{Gemcutter::HOST}/gems/#{latest_version&.gem_file_name}",
        homepage_uri:      versioned_links&.homepage_uri,
        wiki_uri:          versioned_links&.wiki_uri,
        documentation_uri: versioned_links&.documentation_uri,
        mailing_list_uri:  versioned_links&.mailing_list_uri,
        source_code_uri:   versioned_links&.source_code_uri,
        bug_tracker_uri:   versioned_links&.bug_tracker_uri,
        changelog_uri:     versioned_links&.changelog_uri,
        funding_uri:       versioned_links&.funding_uri,
        yanked:            versions.none?(&:indexed?),
        summary:           latest_version&.summary,
        description:       latest_version&.description,
        updated:           updated_at,
        dependencies: {
          development: deps&.select { |r| r.rubygem && r.scope == "development" },
          runtime: deps&.select { |r| r.rubygem && r.scope == "runtime" }
        }
      }.merge!(suggest_json)
    end

    def self.legacy_search(query)
      conditions = <<~SQL.squish
        versions.indexed and
          (UPPER(name) LIKE UPPER(:query) OR
           UPPER(TRANSLATE(name, :match, :replace)) LIKE UPPER(:query))
      SQL

      replace_characters = " " * Patterns::SPECIAL_CHARACTERS.length
      where(conditions, query: "%#{query.strip}%", match: Patterns::SPECIAL_CHARACTERS, replace: replace_characters)
        .includes(:latest_version, :gem_download)
        .references(:versions)
        .by_downloads
    end

    private

    def suggest_json
      {
        suggest: {
          input: name,
          weight: downloads,
          contexts: {
            yanked: versions.none?(&:indexed?)
          }
        }
      }
    end
  end
end
