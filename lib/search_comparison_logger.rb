# frozen_string_literal: true

# Development-only side-by-side comparison of DatabaseSearcher and ElasticSearcher.
#
# When enabled (config.x.search_comparison_log), every plain-text search and
# autocomplete request runs against both engines and writes the timings, totals
# and ranked names to log/search_comparison.log. It never affects the response:
# the served results come from whichever engine FeatureFlag::DB_SEARCH selects.
class SearchComparisonLogger
  LOG_PATH = Rails.root.join("log/search_comparison.log")
  COLUMN_WIDTH = 36

  class << self
    def enabled?
      Rails.configuration.x.search_comparison_log == true
    end

    def logger
      @logger ||= ActiveSupport::Logger.new(LOG_PATH).tap { |l| l.formatter = ->(*, msg) { "#{msg}\n" } }
    end

    attr_writer :logger

    def log_search(query, page:, served_by:)
      return unless enabled? && DatabaseSearcher.plain_query?(query)

      database = measure { DatabaseSearcher.new(query, page:).search }
      opensearch = measure { ElasticSearcher.new(query, page:).search }

      write("search #{query.inspect} page=#{page} served_by=#{served_by}",
        database: summarize_search(*database),
        opensearch: summarize_search(*opensearch))
    rescue StandardError => e
      logger.error("search comparison failed for #{query.inspect}: #{e.class}: #{e.message}")
    end

    def log_suggestions(query, served_by:)
      return unless enabled? && DatabaseSearcher.plain_query?(query)

      database = measure { DatabaseSearcher.new(query).suggestions }
      opensearch = measure { ElasticSearcher.new(query).suggestions }

      write("autocomplete #{query.inspect} served_by=#{served_by}",
        database: summarize_names(*database),
        opensearch: summarize_names(*opensearch))
    rescue StandardError => e
      logger.error("autocomplete comparison failed for #{query.inspect}: #{e.class}: #{e.message}")
    end

    private

    def measure
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      result = yield
      [result, (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000]
    end

    def summarize_search((error, gems), duration_ms)
      return { duration_ms:, error:, total: 0, names: [] } unless gems

      { duration_ms:, error:, total: gems.total_count, names: gems.map(&:name) }
    end

    def summarize_names(names, duration_ms)
      { duration_ms:, error: nil, total: names.size, names: }
    end

    def write(header, database:, opensearch:)
      lines = ["=== #{Time.current.iso8601} #{header}", *summary_rows(database, opensearch),
               *ranking_rows(database[:names], opensearch[:names]), *overlap_rows(database[:names], opensearch[:names])]
      logger.info("#{lines.join("\n")}\n")
    end

    def summary_rows(database, opensearch)
      rows = [row("", "database", "opensearch"),
              row("time", format("%.1fms", database[:duration_ms]), format("%.1fms", opensearch[:duration_ms])),
              row("total", database[:total], opensearch[:total])]
      rows << row("error", database[:error], opensearch[:error]) if database[:error] || opensearch[:error]
      rows
    end

    def ranking_rows(database_names, opensearch_names)
      Array.new([database_names.size, opensearch_names.size].max) do |i|
        row(i + 1, database_names[i], opensearch_names[i])
      end
    end

    def overlap_rows(database_names, opensearch_names)
      shared = database_names & opensearch_names
      only_database = database_names - shared
      only_opensearch = opensearch_names - shared

      rows = ["  overlap: #{shared.size} of #{[database_names.size, opensearch_names.size].max} on this page"]
      rows << "  only database: #{only_database.join(', ')}" if only_database.any?
      rows << "  only opensearch: #{only_opensearch.join(', ')}" if only_opensearch.any?
      rows
    end

    def row(label, left, right)
      format("  %-6s %-#{COLUMN_WIDTH}s %s", label, left.to_s.truncate(COLUMN_WIDTH - 1), right)
    end
  end
end
