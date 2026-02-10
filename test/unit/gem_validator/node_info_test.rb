require "test_helper"

class GemValidator::NodeInfoTest < Minitest::Test
  include GemspecYamlTemplateHelpers

  def test_ignored_tag_binary_is_accepted
    yaml = gemspec_yaml_template.sub("files: []", "files:\n- !binary |-\n    dGVzdC50eHQ=")

    assert GemValidator::Package.validate_gemspec_yaml(yaml)
  end

  def test_ignored_tag_str_is_accepted
    yaml = gemspec_yaml_template.sub("description:", "description: !str")

    assert GemValidator::Package.validate_gemspec_yaml(yaml)
  end

  def test_ignored_tag_timestamp_is_accepted
    yaml = gemspec_yaml_template.sub(
      "date: 1980-01-02 00:00:00.000000000 Z",
      "date: !timestamp 1980-01-02 00:00:00.000000000 Z"
    )

    assert GemValidator::Package.validate_gemspec_yaml(yaml)
  end

  def test_tag_alias_version_requirement_is_accepted
    yaml = gemspec_yaml_template.sub(
      "required_ruby_version: !ruby/object:Gem::Requirement",
      "required_ruby_version: !ruby/object:Gem::Version::Requirement"
    )

    assert GemValidator::Package.validate_gemspec_yaml(yaml)
  end

  def test_unrecognized_tag_is_rejected
    yaml = "#{gemspec_yaml_template}exploit: !ruby/object:Kernel {}\n"

    assert_raises GemValidator::Package::InvalidGemspec do
      GemValidator::Package.validate_gemspec_yaml(yaml)
    end
  end

  def test_read_tag_returns_nil_for_ignored_tags
    GemValidator::NodeInfo::IGNORED_TAGS.each do |tag|
      node = Psych::Nodes::Scalar.new("foo", nil, tag, false)

      assert_nil GemValidator::NodeInfo.read_tag(node), "expected nil for ignored tag #{tag.inspect}"
    end
  end

  def test_read_tag_returns_aliased_tag
    node = Psych.parse("--- !ruby/object:Gem::Version::Requirement\nrequirements: []").children.first

    assert_equal "!ruby/object:Gem::Requirement", GemValidator::NodeInfo.read_tag(node)
  end

  def test_read_tag_passes_through_unrecognized_tags
    node = Psych.parse("--- !ruby/object:Gem::Specification\nname: test").children.first

    assert_equal "!ruby/object:Gem::Specification", GemValidator::NodeInfo.read_tag(node)
  end
end
