# frozen_string_literal: true

# One row of the search results page, rendered from an OpenSearch hit (`_source`).
class Search::ResultComponent < ApplicationComponent
  register_output_helper :download_count_component
  register_output_helper :short_info
  register_value_helper :time_ago_in_words

  prop :rubygem

  def view_template
    article(class: ROW_CLASSES, data: { testid: "search-result" }) do
      div(class: "flex flex-col sm:flex-row sm:items-baseline sm:gap-3 min-w-0") do
        h2(class: "shrink-0 text-b1 font-semibold text-neutral-900 dark:text-white group-hover:text-orange-500 transition-colors") do
          # The stretched ::after makes the whole row clickable while the Source link stays separately clickable.
          link_to @rubygem.name, rubygem_path(@rubygem.name),
            class: "no-underline text-inherit after:absolute after:inset-0 after:rounded-md",
            data: { testid: "rubygem-name" }
        end
        p(class: "text-b3 text-neutral-600 dark:text-neutral-400 truncate") { short_info(@rubygem) }
      end

      div(class: "flex flex-wrap items-center gap-x-2 gap-y-1 text-b3 text-neutral-600 dark:text-neutral-400") do
        meta_items.each_with_index do |item, index|
          span(aria_hidden: "true") { "·" } if index.positive?
          item.call
        end
      end

      div(class: "flex items-center justify-between gap-4") do
        div(class: "flex flex-wrap gap-2") { source_badge }
        download_count_component(@rubygem)
      end
    end
  end

  private

  ROW_CLASSES = "relative flex flex-col gap-2 px-4 py-4 rounded-md " \
                "hover:bg-orange-50 dark:hover:bg-orange-950 " \
                "border-b border-neutral-200 dark:border-neutral-800 group"
  BADGE_CLASSES = "relative z-10 inline-flex items-center px-2 py-0.5 rounded-sm text-c3 font-semibold no-underline " \
                  "bg-neutral-100 dark:bg-neutral-800 text-neutral-700 dark:text-neutral-300 " \
                  "hover:bg-orange-100 dark:hover:bg-orange-900 hover:text-orange-700 dark:hover:text-orange-300"

  def meta_items
    items = []
    items << -> { version_tag } if @rubygem.version
    items << -> { updated_tag } if updated_at
    items << -> { span(data: { testid: "licenses" }) { licenses_text } } if licenses.any?
    items
  end

  def version_tag
    code(class: "px-1.5 text-c3 bg-green-200 dark:bg-green-800 rounded-sm text-neutral-900 dark:text-white") { @rubygem.version }
  end

  def updated_tag
    time_tag(updated_at, t("time_ago", duration: time_ago_in_words(updated_at)), title: view_context.l(updated_at.to_date, format: :long))
  end

  def source_badge
    uri = @rubygem["source_code_uri"]
    return unless uri.is_a?(String) && uri.match?(%r{\Ahttps?://}i)

    a(href: uri, class: BADGE_CLASSES, rel: "nofollow noopener", data: { testid: "source-link" }) { t(".source") }
  end

  def updated_at
    return @updated_at if defined?(@updated_at)
    @updated_at = @rubygem["updated"].presence && Time.zone.parse(@rubygem["updated"])
  end

  def licenses
    Array.wrap(@rubygem["licenses"]).compact_blank
  end

  def licenses_text
    shown = licenses.first(2).join(", ")
    hidden = licenses.size - 2
    hidden.positive? ? t(".more_licenses", licenses: shown, count: hidden) : shown
  end
end
