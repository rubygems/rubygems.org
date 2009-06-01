module RubygemsHelper
  def link_to_page(text, url)
    link_to text, url if url
  end
end
