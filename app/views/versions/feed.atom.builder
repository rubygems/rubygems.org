xml.instruct!

xml.feed "xmlns" => "http://www.w3.org/2005/Atom" do

  xml.title   "Gemcutter | Latest Gems"
  xml.link    "rel" => "self",      "href" => rubygems_url(:format => :atom)
  xml.link    "rel" => "alternate", "href" => rubygems_url
  xml.id      rubygems_url

  xml.updated(@versions.first.updated_at.strftime("%Y-%m-%dT%H:%M:%SZ")) if @versions.any?

  xml.author  { xml.name "Gemcutter" }

  @versions.each do |version|
    xml.entry do
      xml.title     version.to_title
      xml.link      "rel" => "alternate", "href" => rubygem_version_url(version.rubygem, version.slug)
      xml.id        rubygem_version_url(version.rubygem, version.slug)
      xml.updated   version.created_at.strftime("%Y-%m-%dT%H:%M:%SZ")
      xml.author    {|author| author.name h(version.authors) }
      xml.summary   version.summary if version.summary?
      xml.content   "type" => "html" do
        xml.text!   h(version.description)
      end
    end
  end
end
