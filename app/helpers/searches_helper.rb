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

  def aggregation_match_count(aggregration, field)
    count = aggregration["buckets"][field]["doc_count"]
    return unless count > 0

    path = search_path(params: { query: "#{field}:#{params[:query]}" })
    link_to "#{field.capitalize} (#{count})", path, class: CHIP_CLASS
  end

  def aggregation_count(aggregration, duration, buckets_pos)
    count = aggregration["buckets"][buckets_pos]["doc_count"]
    return unless count > 0

    time_ago = (Time.zone.today - duration).to_fs(:db)
    path = search_path(params: { query: "#{params[:query]} AND updated:>=#{time_ago}" })
    update_info = (duration == 30.days ? t("searches.show.month_update", count: count) : t("searches.show.week_update", count: count))
    link_to update_info, path, class: CHIP_CLASS
  end

  def aggregation_yanked(yanked_gem)
    return unless yanked_gem

    path = search_path(params: { query: params[:query], yanked: true })
    link_to t("searches.show.yanked", count: 1), path, class: CHIP_CLASS
  end

  private

  CHIP_CLASS = "px-3 py-1 rounded-full text-xs font-semibold uppercase tracking-wide no-underline " \
               "bg-neutral-100 dark:bg-neutral-800 text-neutral-700 dark:text-neutral-300 " \
               "hover:bg-orange-100 dark:hover:bg-orange-900 hover:text-orange-700 dark:hover:text-orange-300 " \
               "transition-colors"

  def not_empty?(response)
    response["hits"]["total"]["value"] != 0
  end
end
