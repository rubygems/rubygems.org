module UrlHelper
  def prepend_https(url)
    return "" if url.blank?
    return url if url.start_with?("https://")
    "https://#{url}"
  end
end
