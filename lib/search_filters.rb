# frozen_string_literal: true

# Filter and sort state of the search page (`/search`), parsed from URL params so
# results stay shareable. Unknown or malformed values are dropped, so every URL
# renders. Builds the OpenSearch post_filter, sort and facet aggregations.
#
# Facets use post_filter: the query and each facet's counts ignore that facet's
# own selection, so picking "MIT" still shows how many gems are Apache-2.0.
class SearchFilters
  SORTS = %w[relevance downloads updated name].freeze
  DEFAULT_SORT = "relevance"
  # Index field `updated` is Rubygem#updated_at, which every version change touches.
  UPDATED_WITHIN = { "week" => "now-7d/d", "month" => "now-30d/d", "year" => "now-1y/d" }.freeze
  # `licenses` has no explicit mapping; OpenSearch maps it dynamically as text with a keyword subfield.
  LICENSE_FIELD = "licenses.keyword"
  MAX_LICENSES = 10
  LICENSE_FACET_SIZE = 10

  attr_reader :sort, :updated, :licenses

  def self.from_params(params)
    new(sort: params[:sort], updated: params[:updated], licenses: params[:license])
  end

  def initialize(sort: nil, updated: nil, licenses: nil)
    @sort = SORTS.include?(sort) ? sort : DEFAULT_SORT
    @updated = updated if UPDATED_WITHIN.key?(updated)
    @licenses = Array.wrap(licenses).grep(String).compact_blank.uniq.first(MAX_LICENSES).freeze
  end

  def with(**changes)
    self.class.new(sort:, updated:, licenses:, **changes)
  end

  def active?
    updated.present? || licenses.any?
  end

  def to_params
    { sort: (sort unless sort == DEFAULT_SORT), updated: updated, license: licenses.presence }.compact
  end

  def post_filter
    { bool: { filter: filter_clauses } } if active?
  end

  def sort_clause
    case sort
    when "downloads" then [{ downloads: { order: "desc" } }, NAME_SORT]
    when "updated" then [{ updated: { order: "desc" } }, NAME_SORT]
    when "name" then [NAME_SORT]
    end
  end

  def aggregations
    {
      updated_facet: {
        filter: { bool: { filter: filter_clauses(except: :updated) } },
        aggs: { ranges: { date_range: { field: "updated", ranges: UPDATED_WITHIN.map { |key, from| { key:, from: } } } } }
      },
      license_facet: {
        filter: { bool: { filter: filter_clauses(except: :licenses) } },
        aggs: { values: { terms: { field: LICENSE_FIELD, size: LICENSE_FACET_SIZE } } }
      }
    }
  end

  # => { "week" => 3, "month" => 10, "year" => 42 }
  def updated_counts(aggregations)
    buckets = aggregations&.dig("updated_facet", "ranges", "buckets") || []
    buckets.to_h { |bucket| [bucket["key"], bucket["doc_count"]] }
  end

  # => { "MIT" => 120, "Apache-2.0" => 12 }, plus selected licenses outside the
  # top buckets with a nil (unknown) count so they can still be unchecked.
  def license_counts(aggregations)
    buckets = aggregations&.dig("license_facet", "values", "buckets") || []
    counts = buckets.to_h { |bucket| [bucket["key"], bucket["doc_count"]] }
    licenses.each { |license| counts[license] = nil unless counts.key?(license) }
    counts
  end

  # Case-insensitive A–Z; `name.unanalyzed` is a plain keyword, which would sort "Zlib" before "abc".
  NAME_SORT = {
    _script: {
      type: "string",
      order: "asc",
      script: { lang: "painless", source: "doc['name.unanalyzed'].value.toLowerCase()" }
    }
  }.freeze
  private_constant :NAME_SORT

  private

  def filter_clauses(except: nil)
    clauses = []
    clauses << { range: { updated: { gte: UPDATED_WITHIN[updated] } } } if updated && except != :updated
    clauses << { terms: { LICENSE_FIELD => licenses } } if licenses.any? && except != :licenses
    clauses
  end
end
