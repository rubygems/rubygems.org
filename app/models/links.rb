class Links
  # Links available for indexed gems
  LINKS = {
    "home"      => "homepage_uri",
    "changelog" => "changelog_uri",
    "code"      => "source_code_uri",
    "docs"      => "documentation_uri",
    "wiki"      => "wiki_uri",
    "mail"      => "mailing_list_uri",
    "bugs"      => "bug_tracker_uri",
    "download"  => "download_uri",
    "funding"   => "funding_uri"
  }.freeze

  # Links available for non-indexed gems
  NON_INDEXED_LINKS = {
    "docs"      => "documentation_uri"
  }.freeze

  attr_accessor :rubygem, :version, :linkset, :link_verifications

  def initialize(rubygem, version)
    self.rubygem = rubygem
    self.version = version
    self.linkset = rubygem.linkset
    self.link_verifications = rubygem.link_verifications.verified.for_uri(version ? each.map { |_, url| url } : []).strict_loading
  end

  def links
    version.indexed ? LINKS : NON_INDEXED_LINKS
  end

  delegate :keys, to: :links

  def unique_links
    links.uniq do |_short, long|
      send(long)
    end
  end

  def each
    return enum_for(:each) unless block_given?
    unique_links.each do |short, long|
      value = send(long)
      yield short, value if value
    end
  end

  def verified?(uri)
    # intentionally using #any? here because we want to ensure the query is materialized only once to avoid an N+1
    link_verifications.any? { |lv| lv.uri == uri }
  end

  # documentation uri:
  # if metadata has it defined, use that
  # or if linksets has it defined, use that
  # else, generate one from gem name and version number
  def documentation_uri
    return version.metadata["documentation_uri"].presence if version.metadata_uri_set?
    linkset&.docs&.presence || "https://www.rubydoc.info/gems/#{rubygem.name}/#{version.number}"
  end

  # technically this is a path
  def download_uri
    "/downloads/#{version.gem_file_name}" if version.indexed
  end

  # excluded from metadata_uri_set? check
  def homepage_uri
    version.metadata["homepage_uri"].presence || linkset&.home
  end

  # define getters for each of the uris (both short `home` or long `homepage_uri` versions)
  # don't define for download_uri since it has special logic and is already defined
  # using a try because linkset does not define all the uri attributes
  LINKS.each do |short, long|
    unless method_defined?(long)
      define_method(long) do
        return version.metadata[long].presence if version.metadata_uri_set?
        linkset.try(short)
      end
    end
    alias_method short, long
  end
end
