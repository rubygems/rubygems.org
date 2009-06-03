module RubygemsHelper
  def link_to_page(text, url)
    link_to text, url unless url.blank?
  end
end
