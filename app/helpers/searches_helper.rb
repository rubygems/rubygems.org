# frozen_string_literal: true

module SearchesHelper
  def es_suggestions(gems)
    return false if gems.size >= 1
    return false unless gems.respond_to?(:response)
    suggestions = gems.response["suggest"]
    return false if suggestions.blank?
    return false if suggestions["suggest_name"].blank?
    return false if suggestions["suggest_name"][0]["options"].empty?
    suggestions.map { |_k, v| v.first["options"] }.flatten.pluck("text").uniq
  end

  def aggregation_yanked(yanked_gem)
    return unless yanked_gem

    path = search_path(params: { query: params[:query], yanked: true })
    link_to t("searches.show.yanked", count: 1), path, class: CHIP_CLASS
  end

  CHIP_CLASS = "px-3 py-1 rounded-full text-xs font-semibold uppercase tracking-wide no-underline " \
               "bg-neutral-100 dark:bg-neutral-800 text-neutral-700 dark:text-neutral-300 " \
               "hover:bg-orange-100 dark:hover:bg-orange-900 hover:text-orange-700 dark:hover:text-orange-300 " \
               "transition-colors"
end
