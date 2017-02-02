class Links
  # Links available for indexed gems
  LINKS = {
    'home'     => 'homepage_uri',
    'code'     => 'source_code_uri',
    'docs'     => 'documentation_uri',
    'wiki'     => 'wiki_uri',
    'mail'     => 'mailing_list_uri',
    'bugs'     => 'bug_tracker_uri',
    'download' => 'download_uri'
  }.freeze

  # Links available for non-indexed gems
  NON_INDEXED_LINKS = {
    'docs'     => 'documentation_uri'
  }.freeze

  attr_accessor :rubygem, :version, :linkset

  def initialize(rubygem, version)
    self.rubygem = rubygem
    self.version = version
    self.linkset = rubygem.linkset
  end

  def links
    version.indexed ? LINKS : NON_INDEXED_LINKS
  end

  delegate :keys, to: :links

  def each
    return enum_for(:each) unless block_given?
    links.each do |short, long|
      value = send(long)
      yield short, value if value
    end
  end

  # documentation uri:
  # if metadata has it defined, use that
  # or if linksets has it defined, use that
  # else, generate one from gem name and version number
  def documentation_uri
    version.metadata["documentation_uri"].presence ||
      linkset&.docs&.presence ||
      "http://www.rubydoc.info/gems/#{rubygem.name}/#{version.number}"
  end

  # technically this is a path
  def download_uri
    "/downloads/#{version.full_name}.gem" if version.indexed
  end

  # define getters for each of the uris (both short `home` or long `homepage_uri` versions)
  # don't define for download_uri since it has special logic and is already defined
  LINKS.each do |short, long|
    unless method_defined?(long)
      define_method(long) do
        version.metadata[long].presence || linkset&.public_send(short)
      end
    end
    alias_method short, long
  end
end
