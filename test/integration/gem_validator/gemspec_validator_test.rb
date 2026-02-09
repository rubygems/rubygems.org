require "test_helper"

class GemValidator::InvalidGemspecTest < Minitest::Test
  include Gem::DefaultUserInteraction
  include GemHelpers
  include GemspecYamlTemplateHelpers

  def setup
    @valid_gemspec = new_gemspec("valid-gem", "1.0.0", "a valid gem", "ruby")
  end

  # Valid Gemspec tests

  def test_full_name_compatibility
    spec = Gem::Specification.new
    spec.name = "testname"
    spec.version = "1.0.0"

    ast = Psych.parse(spec.to_yaml)
    ast_spec = GemValidator::YAMLGemspec.new(ast)

    assert_equal spec.full_name, ast_spec.full_name
  end

  def test_non_standard_license
    @valid_gemspec.licenses = ["FOO"]

    assert_equal ["FOO"], Gem::Specification.from_yaml(@valid_gemspec.to_yaml).licenses

    use_ui Null.new do
      @valid_gemspec.validate
    end

    assert GemValidator::Package.validate_gemspec_yaml @valid_gemspec.to_yaml
  end

  def test_one_letter_is_allowed
    spec = Gem::Specification.new
    spec.name = "a"
    spec.version = "1.0.0"
    spec.summary = "hello world"
    spec.authors = ["hello world"]

    use_ui Null.new do
      assert spec.validate
    end

    assert GemValidator::Package.validate_gemspec_yaml spec.to_yaml
  end

  def test_many_letters_ok
    spec = Gem::Specification.new
    spec.name = "abcde"
    spec.version = "1.0.0"
    spec.summary = "hello world"
    spec.authors = ["hello world"]

    use_ui Null.new do
      assert spec.validate
    end

    assert GemValidator::Package.validate_gemspec_yaml spec.to_yaml
  end

  def test_name_with_dash_is_allowed
    spec = Gem::Specification.new
    spec.name = "a-bc"
    spec.version = "1.0.0"
    spec.summary = "hello world"
    spec.authors = ["hello world"]

    use_ui Null.new do
      assert spec.validate
    end

    assert GemValidator::Package.validate_gemspec_yaml gemspec_yaml_template(name: "'a-bc'")
  end

  def test_name_with_underscore_is_allowed
    spec = Gem::Specification.new
    spec.name = "a_bc"
    spec.version = "1.0.0"
    spec.summary = "hello world"
    spec.authors = ["hello world"]

    use_ui Null.new do
      assert spec.validate
    end

    assert GemValidator::Package.validate_gemspec_yaml gemspec_yaml_template(name: "'a_bc'")
  end

  # Invalid Gemspec tests

  def test_reject_yaml_syntax_wrapped_in_invalid_gemspec
    assert_raises GemValidator::Package::InvalidGemspec do
      GemValidator::Package.validate_gemspec_yaml(<<~EOYML)
        key: value
          bad_indent: this is indented incorrectly
        another_key: value
      EOYML
    end
  end

  def test_reject_metadata_key_value_length_limits
    @valid_gemspec.metadata = { "x" * 128 => "y" * 1024 }

    assert_valid_gemspec @valid_gemspec
    assert_valid_gemspec_yaml @valid_gemspec.to_yaml
  end

  def test_reject_metadata_key_value_too_long
    # key is too long
    @valid_gemspec.metadata = { "x" * 129 => "y" * 1024 }

    assert_raises Gem::InvalidSpecificationException do
      use_ui Null.new do
        assert @valid_gemspec.validate
      end
    end

    assert_raises GemValidator::Package::InvalidGemspec do
      GemValidator::Package.validate_gemspec_yaml @valid_gemspec.to_yaml
    end
  end

  def test_reject_metadata_value_too_long
    # value is too long
    @valid_gemspec.metadata = { "x" * 128 => "y" * 1025 }

    assert_raises Gem::InvalidSpecificationException do
      use_ui Null.new do
        assert @valid_gemspec.validate
      end
    end

    assert_raises GemValidator::Package::InvalidGemspec do
      GemValidator::Package.validate_gemspec_yaml @valid_gemspec.to_yaml
    end
  end

  def test_reject_uris_have_max_length
    %w[
      homepage_uri changelog_uri source_code_uri
      documentation_uri wiki_uri mailing_list_uri
      bug_tracker_uri download_uri funding_uri
    ].each do |name|
      @valid_gemspec.metadata = {
        name => "http://example.org/#{'x' * 1024}"
      }

      assert_raises Gem::InvalidSpecificationException do
        use_ui Null.new do
          assert @valid_gemspec.validate
        end
      end

      assert_raises GemValidator::Package::InvalidGemspec do
        GemValidator::Package.validate_gemspec_yaml @valid_gemspec.to_yaml
      end
    end
  end

  def test_reject_metadata_uri_validation
    @valid_gemspec.metadata = {
      "homepage_uri" => "world",
      "hello" => "world"
    }

    assert_raises Gem::InvalidSpecificationException do
      use_ui Null.new do
        assert @valid_gemspec.validate
      end
    end

    assert_raises GemValidator::Package::InvalidGemspec do
      GemValidator::Package.validate_gemspec_yaml @valid_gemspec.to_yaml
    end
  end

  def test_reject_nil_license
    @valid_gemspec.licenses = nil

    assert_empty Gem::Specification.from_yaml(@valid_gemspec.to_yaml).licenses

    use_ui Null.new do
      @valid_gemspec.validate
    end

    GemValidator::Package.validate_gemspec_yaml @valid_gemspec.to_yaml
  end

  def test_reject_license_is_too_long
    @valid_gemspec.licenses = ["X" * 64]

    use_ui Null.new do
      @valid_gemspec.validate
    end

    GemValidator::Package.validate_gemspec_yaml @valid_gemspec.to_yaml

    @valid_gemspec.licenses = ["X" * 65]

    assert_raises Gem::InvalidSpecificationException do
      use_ui Null.new do
        @valid_gemspec.validate
      end
    end

    assert_raises GemValidator::Package::InvalidGemspec do
      GemValidator::Package.validate_gemspec_yaml @valid_gemspec.to_yaml
    end

    @valid_gemspec.licenses = [["X" * 65]]

    assert_raises Gem::InvalidSpecificationException do
      use_ui Null.new do
        @valid_gemspec.validate
      end
    end

    assert_raises GemValidator::Package::InvalidGemspec do
      GemValidator::Package.validate_gemspec_yaml @valid_gemspec.to_yaml
    end
  end

  def test_reject_empty_authors
    @valid_gemspec.authors = []

    assert_raises Gem::InvalidSpecificationException do
      use_ui Null.new do
        @valid_gemspec.validate
      end
    end

    assert_raises GemValidator::Package::InvalidGemspec do
      GemValidator::Package.validate_gemspec_yaml gemspec_yaml_template(authors: [])
    end
  end

  def test_reject_missing_authors
    @valid_gemspec.authors = nil

    assert_raises Gem::InvalidSpecificationException do
      use_ui Null.new do
        @valid_gemspec.validate
      end
    end

    e = assert_raises GemValidator::Package::InvalidGemspec do
      GemValidator::Package.validate_gemspec_yaml gemspec_yaml_template(authors: nil)
    end

    assert_kind_of YAMLSchema::Validator::MissingRequiredField, e.cause
  end

  def test_reject_missing_summary
    spec = Gem::Specification.new
    spec.name = "hello"
    spec.version = "1.0.0"
    spec.authors = ["hello world"]

    assert_raises Gem::InvalidSpecificationException do
      use_ui Null.new do
        spec.validate
      end
    end

    e = assert_raises GemValidator::Package::InvalidGemspec do
      GemValidator::Package.validate_gemspec_yaml gemspec_yaml_template(summary: nil)
    end

    assert_kind_of YAMLSchema::Validator::MissingRequiredField, e.cause
  end

  def test_reject_missing_version
    spec = Gem::Specification.new
    spec.name = "hello"
    spec.summary = "hello world"
    spec.authors = ["hello world"]

    assert_raises Gem::InvalidSpecificationException do
      use_ui Null.new do
        spec.validate
      end
    end

    e = assert_raises GemValidator::Package::InvalidGemspec do
      GemValidator::Package.validate_gemspec_yaml gemspec_yaml_template(version: nil)
    end
    assert_kind_of YAMLSchema::Validator::MissingRequiredField, e.cause
  end

  def test_reject_missing_name
    spec = Gem::Specification.new
    spec.version = "1.0.0"
    spec.summary = "hello world"
    spec.authors = ["hello world"]

    assert_raises Gem::InvalidSpecificationException do
      use_ui Null.new do
        spec.validate
      end
    end

    e = assert_raises GemValidator::Package::InvalidGemspec do
      GemValidator::Package.validate_gemspec_yaml gemspec_yaml_template(name: nil)
    end

    assert_kind_of YAMLSchema::Validator::MissingRequiredField, e.cause
  end

  def test_reject_one_digit_name
    spec = Gem::Specification.new
    spec.name = "0"
    spec.version = "1.0.0"
    spec.summary = "hello world"
    spec.authors = ["hello world"]

    assert_raises Gem::InvalidSpecificationException do
      use_ui Null.new do
        assert spec.validate
      end
    end

    assert_raises GemValidator::Package::InvalidGemspec do
      GemValidator::Package.validate_gemspec_yaml gemspec_yaml_template(name: "'0'")
    end
  end

  def test_reject_many_digits_name
    spec = Gem::Specification.new
    spec.name = "1234"
    spec.version = "1.0.0"
    spec.summary = "hello world"
    spec.authors = ["hello world"]

    assert_raises Gem::InvalidSpecificationException do
      use_ui Null.new do
        assert spec.validate
      end
    end

    assert_raises GemValidator::Package::InvalidGemspec do
      GemValidator::Package.validate_gemspec_yaml gemspec_yaml_template(name: "'1234'")
    end
  end

  def test_reject_name_with_leading_dash
    spec = Gem::Specification.new
    spec.name = "-"
    spec.version = "1.0.0"
    spec.summary = "hello world"
    spec.authors = ["hello world"]

    assert_raises Gem::InvalidSpecificationException do
      use_ui Null.new do
        assert spec.validate
      end
    end

    assert_raises GemValidator::Package::InvalidGemspec do
      GemValidator::Package.validate_gemspec_yaml gemspec_yaml_template(name: "'-'")
    end

    spec = Gem::Specification.new
    spec.name = "-abc"
    spec.version = "1.0.0"
    spec.summary = "hello world"
    spec.authors = ["hello world"]

    assert_raises Gem::InvalidSpecificationException do
      use_ui Null.new do
        assert spec.validate
      end
    end

    assert_raises GemValidator::Package::InvalidGemspec do
      GemValidator::Package.validate_gemspec_yaml gemspec_yaml_template(name: "'-abc'")
    end
  end

  def test_reject_dot_name # rubocop:disable Metrics/MethodLength
    spec = Gem::Specification.new
    spec.name = "."
    spec.version = "1.0.0"
    spec.summary = "hello world"
    spec.authors = ["hello world"]

    assert_raises Gem::InvalidSpecificationException do
      use_ui Null.new do
        assert spec.validate
      end
    end

    assert_raises GemValidator::Package::InvalidGemspec do
      GemValidator::Package.validate_gemspec_yaml gemspec_yaml_template(name: "'.'")
    end

    spec = Gem::Specification.new
    spec.name = ".abc"
    spec.version = "1.0.0"
    spec.summary = "hello world"
    spec.authors = ["hello world"]

    assert_raises Gem::InvalidSpecificationException do
      use_ui Null.new do
        assert spec.validate
      end
    end

    assert_raises GemValidator::Package::InvalidGemspec do
      GemValidator::Package.validate_gemspec_yaml gemspec_yaml_template(name: "'.abc'")
    end

    spec = Gem::Specification.new
    spec.name = "a.bc"
    spec.version = "1.0.0"
    spec.summary = "hello world"
    spec.authors = ["hello world"]

    use_ui Null.new do
      assert spec.validate
    end

    assert GemValidator::Package.validate_gemspec_yaml gemspec_yaml_template(name: "'a.bc'")
  end

  def test_reject_underscore_name
    spec = Gem::Specification.new
    spec.name = "_"
    spec.version = "1.0.0"
    spec.summary = "hello world"
    spec.authors = ["hello world"]

    assert_raises Gem::InvalidSpecificationException do
      use_ui Null.new do
        assert spec.validate
      end
    end

    assert_raises GemValidator::Package::InvalidGemspec do
      GemValidator::Package.validate_gemspec_yaml gemspec_yaml_template(name: "'_'")
    end
  end

  def test_reject_name_with_leading_underscore
    spec = Gem::Specification.new
    spec.name = "_abc"
    spec.version = "1.0.0"
    spec.summary = "hello world"
    spec.authors = ["hello world"]

    assert_raises Gem::InvalidSpecificationException do
      use_ui Null.new do
        assert spec.validate
      end
    end

    assert_raises GemValidator::Package::InvalidGemspec do
      GemValidator::Package.validate_gemspec_yaml gemspec_yaml_template(name: "'_abc'")
    end
  end

  def test_reject_nil_name
    assert_raises GemValidator::Package::InvalidGemspec do
      GemValidator::Package.validate_gemspec_yaml gemspec_yaml_template(name: nil)
    end
  end

  def test_reject_number_name
    assert_raises GemValidator::Package::InvalidGemspec do
      GemValidator::Package.validate_gemspec_yaml gemspec_yaml_template(name: 1)
    end
  end

  def test_reject_utf8_name
    spec = Gem::Specification.new
    spec.name = "こんにちは"
    spec.version = "1.0.0"
    spec.summary = "hello world"
    spec.authors = ["hello world"]

    assert_raises Gem::InvalidSpecificationException do
      use_ui Null.new do
        spec.validate
      end
    end

    assert_raises GemValidator::Package::InvalidGemspec do
      GemValidator::Package.validate_gemspec_yaml gemspec_yaml_template(name: "こんにちは")
    end
  end

  def test_reject_bogus_dates
    assert_raises GemValidator::Package::InvalidGemspec do
      GemValidator::Package.validate_gemspec_yaml gemspec_yaml_template(name: "test", date: "1980-13-01")
    end

    assert_raises GemValidator::Package::InvalidGemspec do
      GemValidator::Package.validate_gemspec_yaml gemspec_yaml_template(name: "test", date: "19-12-01")
    end

    assert_raises GemValidator::Package::InvalidGemspec do
      GemValidator::Package.validate_gemspec_yaml gemspec_yaml_template(name: "test", date: "1980-12-32")
    end

    assert_raises GemValidator::Package::InvalidGemspec do
      GemValidator::Package.validate_gemspec_yaml gemspec_yaml_template(name: "test", date: "1980-12-00")
    end
  end

  def test_reject_aliases
    assert_raises GemValidator::Package::InvalidGemspec do
      GemValidator::Package.validate_gemspec_yaml gemspec_yaml_template(name: "test", use_yaml_alias: true)
    end
  end

  def test_reject_bogus_version_strings
    assert_raises GemValidator::Package::InvalidGemspec do
      GemValidator::Package.validate_gemspec_yaml gemspec_yaml_template(name: "foo", version: "notversion-123")
    end
  end

  def test_reject_bogus_dep_type
    assert_raises GemValidator::Package::InvalidGemspec do
      GemValidator::Package.validate_gemspec_yaml gemspec_yaml_template(dependencies: [bogus_dep_yaml])
    end
  end

  def test_yaml_gemspec_cert_chain_missing_returns_empty
    yaml = gemspec_yaml_template.gsub(/^cert_chain:.*\n/, "")
    ast = Psych.parse(yaml)
    gemspec = GemValidator::YAMLGemspec.new(ast)

    assert_empty gemspec.cert_chain
  end

  def test_yaml_gemspec_cert_chain_null_returns_empty
    yaml = gemspec_yaml_template.sub("cert_chain: []", "cert_chain:")
    ast = Psych.parse(yaml)
    gemspec = GemValidator::YAMLGemspec.new(ast)

    assert_empty gemspec.cert_chain
  end

  def test_yaml_gemspec_cert_chain_with_values
    yaml = gemspec_yaml_template.sub("cert_chain: []", "cert_chain:\n- cert-data-here")
    ast = Psych.parse(yaml)
    gemspec = GemValidator::YAMLGemspec.new(ast)

    assert_equal ["cert-data-here"], gemspec.cert_chain
  end

  private

  def spec_with_bogus_dep_type(name)
    gemspec_yaml_template(
      name: name,
      authors: ["an-author"],
      summary: "a signed gem",
      dependencies: [bogus_dep_yaml, valid_dev_dep_yaml]
    )
  end

  def bogus_dep_yaml
    <<~YAML.chomp
      - !ruby/object:Gem::Dependency
        name: racc
        requirement: !ruby/object:Gem::Requirement
          requirements:
          - - "~>"
            - !ruby/object:Gem::Version
              version: '1.6'
        type: :notreal
        prerelease: false
        version_requirements: !ruby/object:Gem::Requirement
          requirements:
          - - "~>"
            - !ruby/object:Gem::Version
              version: '1.6'
    YAML
  end

  def valid_dev_dep_yaml
    <<~YAML.chomp
      - !ruby/object:Gem::Dependency
        name: hatstone
        requirement: !ruby/object:Gem::Requirement
          requirements:
          - - "~>"
            - !ruby/object:Gem::Version
              version: 1.0.0
        type: :development
        prerelease: false
        version_requirements: !ruby/object:Gem::Requirement
          requirements:
          - - "~>"
            - !ruby/object:Gem::Version
              version: 1.0.0
    YAML
  end

  def assert_valid_gemspec_yaml(yaml)
    assert GemValidator::Package.validate_gemspec_yaml yaml
  end

  class Null
    def method_missing(...) # rubocop:disable Style/MissingRespondToMissing
    end
  end

  def assert_valid_gemspec(spec)
    use_ui Null.new do
      assert spec.validate
    end
  end
end
