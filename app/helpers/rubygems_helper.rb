module RubygemsHelper

  def link_to_page(text, url)
    link_to text, url unless url.blank?
  end

  def link_to_directory
    ("A".."Z").map { |letter| link_to(letter, rubygems_path(:letter => letter)) }.join
  end
end
