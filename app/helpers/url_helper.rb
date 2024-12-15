module UrlHelper 
  def append_https(url)
    return "" if url.blank?
    return url if url.start_with?("https://")
    return "https://#{url}"
  end 
end 