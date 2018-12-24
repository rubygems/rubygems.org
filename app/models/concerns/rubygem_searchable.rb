module RubygemSearchable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model

    index_name "rubygems-#{Rails.env}"

    delegate :index_document, to: :__elasticsearch__
    delegate :update_document, to: :__elasticsearch__

    def as_indexed_json(_options = {}) # rubocop:disable Metrics/MethodLength
      if (latest_version = versions.most_recent)
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
        gem_uri:           "#{Gemcutter::PROTOCOL}://#{Gemcutter::HOST}/gems/#{latest_version&.full_name}.gem",
        homepage_uri:      versioned_links&.homepage_uri,
        wiki_uri:          versioned_links&.wiki_uri,
        documentation_uri: versioned_links&.documentation_uri,
        mailing_list_uri:  versioned_links&.mailing_list_uri,
        source_code_uri:   versioned_links&.source_code_uri,
        bug_tracker_uri:   versioned_links&.bug_tracker_uri,
        changelog_uri:     versioned_links&.changelog_uri,
        yanked:            versions.none?(&:indexed?),
        summary:           latest_version&.summary,
        description:       latest_version&.description,
        updated:           updated_at,
        dependencies: {
          development: deps&.select { |r| r.rubygem && r.scope == "development" },
          runtime: deps&.select { |r| r.rubygem && r.scope == "runtime" }
        }
      }
    end

    settings number_of_shards: 1,
             number_of_replicas: 1,
             analysis: {
               analyzer: {
                 rubygem: {
                   type: "pattern",
                   pattern: "[\s#{Regexp.escape(Patterns::SPECIAL_CHARACTERS)}]+"
                 }
               }
             }

    mapping do
      indexes :name, type: "text", analyzer: "rubygem" do
        indexes :suggest, analyzer: "simple"
      end
      indexes :summary, type: "text", analyzer: "english" do
        indexes :raw, analyzer: "simple"
      end
      indexes :description, type: "text", analyzer: "english" do
        indexes :raw, analyzer: "simple"
      end
      indexes :yanked, type: "boolean"
      indexes :downloads, type: "integer"
      indexes :updated, type: "date"
    end

    def self.legacy_search(query)
      conditions = <<-SQL
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
  end
end
