module SearchesHelper
  def es_suggestions(gems)
    return false if gems.size >= 1
    return false unless gems.respond_to?(:response)
    suggestions = gems.response.response['suggest']
    return false unless suggestions.present?
    return false unless suggestions['suggest_name'].present?
    return false if suggestions['suggest_name'][0]['options'].empty?
    suggestions.map { |_k, v| v.first['options'] }.flatten.map { |v| v['text'] }.uniq
  end
end
