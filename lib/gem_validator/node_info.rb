module GemValidator::NodeInfo
  IGNORED_TAGS = Set[
    "!", "!binary", "!str", "tag:yaml.org,2002:null",
    "!ruby/regexp", "!timestamp", "!int:Fixnum"
  ].freeze

  TAG_ALIASES = {
    "!ruby/object:Gem::Version::Requirement" => "!ruby/object:Gem::Requirement"
  }.freeze

  def self.read_tag(node)
    tag = node.tag
    return nil if IGNORED_TAGS.include?(tag)

    TAG_ALIASES[tag] || tag
  end
end
