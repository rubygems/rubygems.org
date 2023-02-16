class LinkbackValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, url)
    doc = Nokogiri::HTML(URI.open(url).read)
    selector = url.include?("github.com") ? "[role='link']" : "[rel='rubygem']"
    rel_links = doc.css(selector)

    has_linkback = rel_links.css("[href*='rubygems.org/gem/#{record.rubygem.name}']").present?
    record.errors.add(attribute, "does not contain a #{selector} link back to the gem on rubygems.org") unless has_linkback
  rescue *(HTTP_ERRORS + [RestClient::Exception, SocketError, SystemCallError])
    record.errors.add(attribute, "server error")
  end
end
