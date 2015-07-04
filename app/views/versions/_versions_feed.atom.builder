builder.instruct!

builder.feed "xmlns" => "http://www.w3.org/2005/Atom" do

  builder.title   title
  builder.link    "rel" => "self",      "href" => rubygems_url(format: :atom)
  builder.link    "rel" => "alternate", "href" => rubygems_url
  builder.id      rubygems_url

  builder.updated(versions.first.rubygem.updated_at.iso8601) if versions.any?

  builder.author {xml.name "Rubygems"}

  versions.each do |version|
    builder.entry do
      builder.title     version.to_title
      builder.link      "rel" => "alternate", "href" => rubygem_version_url(version.rubygem, version.slug)
      builder.id        rubygem_version_url(version.rubygem, version.slug)
      builder.updated   version.created_at.iso8601
      builder.author    {|author| author.name h(version.authors)}
      builder.summary   version.summary if version.summary?
      builder.content   "type" => "html" do
        builder.text!   h(version.description)
      end
    end
  end
end
