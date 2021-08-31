module SearchesHelper
  def search_suggestions(gems)
    suggestions = gems.response["suggest"]

    options = suggestions["suggest_name"][0]["options"]
    return if options.empty?

    suggestions.map { |_k, v| v.first["options"] }.flatten.map { |v| v["text"] }.uniq
  rescue NoMethodError
    return
  end

  def aggregation_match_count(aggregration, field)
    count = aggregration["buckets"][field]["doc_count"]
    return unless count > 0

    path = search_path(params: { query: "#{field}:#{params[:query]}" })
    link_to "#{field.capitalize} (#{count})", path, class: "t-link--black"
  end

  def aggregation_count(aggregration, duration, buckets_pos)
    count = aggregration["buckets"][buckets_pos]["doc_count"]
    return unless count > 0

    time_ago = (Time.zone.today - duration).to_s(:db)
    path = search_path(params: { query: "#{params[:query]} AND updated:[#{time_ago} TO *}" })
    update_info = (duration == 30.days ? t("searches.show.month_update", count: count) : t("searches.show.week_update", count: count))
    link_to update_info, path, class: "t-link--black"
  end

  def aggregation_yanked(yanked_gem)
    return unless yanked_gem

    path = search_path(params: { query: params[:query], yanked: true })
    link_to t("searches.show.yanked", count: 1), path, class: "t-link--black"
  end

  def not_empty?(response)
    response["hits"]["total"]["value"] != 0
  end
end
