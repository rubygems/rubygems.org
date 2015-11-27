module SearchesHelper
  def es_suggestions(gems)
    return false unless gems.size < 1
    return false unless gems.respond_to?(:response)
    suggestions = gems.response.response['suggest']
    return flase unless suggestions.present?
    return false unless suggestions['suggest_name'].present?
    return false unless suggestions['suggest_name'][0]['options'].length > 0
    suggestions.map { |_k, v| v.first['options'] }.flatten.map { |v| v['text'] }.uniq
  end
end
