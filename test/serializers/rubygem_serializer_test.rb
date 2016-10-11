require 'test_helper'

class RubygemSerializerTest < ActiveSupport::TestCase
  setup do
    @rubygem = create(:rubygem, name: "testme")
    @version = create(:version, rubygem: @rubygem, number: "0.0.1")
    dep = create(:rubygem, name: "IamDependable")
    create(:dependency, rubygem: dep, version: @version)
  end

  context "JSON" do
    setup do
      serializer = RubygemSerializer.new(@rubygem, version: @version)
      @json_version = serializer.attributes
    end

    should "display correct data" do
      expected_hash = {
        name: "testme",
        downloads: 0,
        version: "0.0.1",
        version_downloads: 0,
        platform: "ruby",
        authors: "Joe User",
        info: "Some awesome gem",
        licenses: "MIT",
        metadata: { "foo" => "bar" },
        sha: "b5d4045c3f466fa91fe2cc6abe79232a1a57cdf104f7a26e716e0a1e2789df78",
        project_uri: "http://localhost/gems/testme",
        gem_uri: "http://localhost/gems/testme-0.0.1.gem",
        homepage_uri: "http://example.com",
        wiki_uri: "http://example.com",
        documentation_uri: "http://example.com",
        mailing_list_uri: "http://example.com",
        source_code_uri: "http://example.com",
        bug_tracker_uri: "http://example.com",
        dependencies: {
          "development" => [],
          "runtime" => [{ name: "IamDependable", requirements: "= 1.0.0" }]
        }
      }

      assert_equal expected_hash, @json_version
    end
  end

  context "XML" do
    setup do
      serializer = RubygemSerializer.new(@rubygem, version: @version)
      xml_version = serializer.to_xml

      @xml = Nokogiri.parse(xml_version)
    end

    should "display correct data" do
      assert_equal "testme", @xml.at_css("name").content
      assert_equal "0", @xml.at_css("downloads").content
      assert_equal "0.0.1", @xml.at_css("version").content
      assert_equal "ruby", @xml.at_css("platform").content
      assert_equal "Joe User", @xml.at_css("authors").content
      assert_equal "Some awesome gem", @xml.at_css("info").content
      assert_equal "MIT", @xml.at_css("licenses").content
      assert_equal "bar", @xml.at_css("metadata foo").content
      assert_equal "b5d4045c3f466fa91fe2cc6abe79232a1a57cdf104f7a26e716e0a1e2789df78", @xml.at_css("sha").content
      assert_equal "http://localhost/gems/testme", @xml.at_css("project-uri").content
      assert_equal "http://localhost/gems/testme-0.0.1.gem", @xml.at_css("gem-uri").content
      assert_equal "http://example.com", @xml.at_css("homepage-uri").content
      assert_equal "http://example.com", @xml.at_css("wiki-uri").content
      assert_equal "http://example.com", @xml.at_css("documentation-uri").content
      assert_equal "http://example.com", @xml.at_css("mailing-list-uri").content
      assert_equal "http://example.com", @xml.at_css("source-code-uri").content
      assert_equal "http://example.com", @xml.at_css("bug-tracker-uri").content
      assert_equal "", @xml.at_css("dependencies development").content
      assert_equal "IamDependable", @xml.at_css("dependencies runtime name").content
      assert_equal "= 1.0.0", @xml.at_css("dependencies runtime requirements").content
    end
  end

  context "YAML" do
    setup do
      serializer = RubygemSerializer.new(@rubygem, version: @version)
      yaml_version = serializer.to_yaml

      @yaml = YAML.load(yaml_version)
    end

    should "display correct data" do
      expected_hash = {
        "name" => "testme",
        "downloads" => 0,
        "version" => "0.0.1",
        "version_downloads" => 0,
        "platform" => "ruby",
        "authors" => "Joe User",
        "info" => "Some awesome gem",
        "licenses" => "MIT",
        "metadata" => { "foo" => "bar" },
        "sha" => "b5d4045c3f466fa91fe2cc6abe79232a1a57cdf104f7a26e716e0a1e2789df78",
        "project_uri" => "http://localhost/gems/testme",
        "gem_uri" => "http://localhost/gems/testme-0.0.1.gem",
        "homepage_uri" => "http://example.com",
        "wiki_uri" => "http://example.com",
        "documentation_uri" => "http://example.com",
        "mailing_list_uri" => "http://example.com",
        "source_code_uri" => "http://example.com",
        "bug_tracker_uri" => "http://example.com",
        "dependencies" => {
          "development" => [],
          "runtime" => [{ "name" => "IamDependable", "requirements" => "= 1.0.0" }]
        }
      }

      assert_equal expected_hash, @yaml
    end
  end
end
