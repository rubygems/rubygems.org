module SearchesHelper
  def es_suggestions(gems)
    return false if gems.size >= 1
    return false unless gems.respond_to?(:response)
    suggestions = gems.response['suggest']
    return false if suggestions.blank?
    return false if suggestions['suggest_name'].blank?
    return false if suggestions['suggest_name'][0]['options'].empty?
    suggestions.map { |_k, v| v.first['options'] }.flatten.map { |v| v['text'] }.uniq
  end

  def aggregation_match_count(aggregration, field)
    count = aggregration['buckets'][field]['doc_count']
    return unless count > 0

    path = search_path(params: { query: "#{field}:#{params[:query]}" })
    link_to "#{field.capitalize} (#{count})", path, class: 't-link--black'
  end

  def aggregation_count(aggregration, duration, buckets_pos)
    count = aggregration['buckets'][buckets_pos]['doc_count']
    return unless count > 0

    time_ago = (Time.zone.today - duration).to_s(:db)
    path = search_path(params: { query: "#{params[:query]} AND updated:[#{time_ago} TO *}" })
    update_info = (duration == 30.days ? t('.month_update', count: count) : t('.week_update', count: count))
    link_to update_info, path, class: 't-link--black'
  end
end
