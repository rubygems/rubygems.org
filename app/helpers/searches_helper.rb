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
    if count > 0
      path = search_path(params: { query: "#{field}:#{params[:query]}" })
      link_to "#{field.capitalize} (#{count})", path, class: 't-link--black'
    end
  end

  def aggregation_week_count(aggregration)
    count = aggregration['buckets'][1]['doc_count']
    if count > 0
      week_ago = (Time.zone.today - 7.days).to_s(:db)
      path = search_path(params: { query: "#{params[:query]} AND updated:[#{week_ago} TO *}" })
      link_to "Updated last week (#{count})", path, class: 't-link--black'
    end
  end

  def aggregation_month_count(aggregration)
    count = aggregration['buckets'][0]['doc_count']
    if count > 0
      month_ago = (Time.zone.today - 30.days).to_s(:db)
      path = search_path(params: { query: "#{params[:query]} AND updated:[#{month_ago} TO *}" })
      link_to "Updated last month (#{count})", path, class: 't-link--black'
    end
  end
end
