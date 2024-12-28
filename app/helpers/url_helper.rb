module UrlHelper
  def display_safe_url(url)
    return "" if url.blank?
    return h(url) if url.start_with?("https://", "http://")
    "https://#{h(url)}"
  end
end
