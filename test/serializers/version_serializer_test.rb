require 'test_helper'

class VersionSerializerTest < ActiveSupport::TestCase
  setup do
    @version = create(:version,
      number: '1.0.1',
      built_at: Date.new(2016, 05, 04),
      created_at: Date.new(2016, 05, 04))
  end

  context 'JSON' do
    setup do
      serializer = VersionSerializer.new(@version)
      @json_version = serializer.attributes
    end

    should 'have proper hash keys' do
      assert_equal(@json_version.keys,
        [:authors,
         :built_at,
         :created_at,
         :description,
         :downloads_count,
         :metadata,
         :number,
         :summary,
         :platform,
         :rubygems_version,
         :ruby_version,
         :prerelease,
         :licenses,
         :requirements,
         :sha])
    end

    should 'display correct data' do
      expected_hash = {
        authors:          "Joe User",
        built_at:         Date.new(2016, 05, 04).in_time_zone("UTC"),
        created_at:       Date.new(2016, 05, 04).in_time_zone("UTC"),
        description:      "Some awesome gem",
        downloads_count:  0,
        metadata:         { "foo" => "bar" },
        number:           "1.0.1",
        summary:          nil,
        platform:         "ruby",
        rubygems_version: ">= 2.6.3",
        ruby_version:     ">= 2.0.0",
        prerelease:       false,
        licenses:         "MIT",
        requirements:     "Opencv",
        sha:              "b5d4045c3f466fa91fe2cc6abe79232a1a57cdf104f7a26e716e0a1e2789df78"
      }

      assert_equal expected_hash, @json_version
    end
  end

  context 'XML' do
    setup do
      serializer = VersionSerializer.new(@version)
      xml_version = serializer.to_xml

      @xml = Nokogiri.parse(xml_version)
    end
    should 'have proper hash keys' do
      assert_equal %w(
        authors
        built-at
        created-at
        description
        downloads-count
        licenses
        metadata
        number
        platform
        prerelease
        requirements
        ruby-version
        rubygems-version
        sha
        summary
      ), @xml.root.children.select(&:element?).map(&:name).sort
    end

    should 'display correct data' do
      assert_equal "Joe User", @xml.at_css("authors").content
      assert_equal Date.new(2016, 05, 04).in_time_zone("UTC"), @xml.at_css("built-at").content
      assert_equal Date.new(2016, 05, 04).in_time_zone("UTC"), @xml.at_css("created-at").content
      assert_equal "Some awesome gem", @xml.at_css("description").content
      assert_equal "0", @xml.at_css("downloads-count").content
      assert_equal "bar", @xml.at_css("metadata foo").content
      assert_equal "1.0.1", @xml.at_css("number").content
      assert_equal "", @xml.at_css("summary").content
      assert_equal "ruby", @xml.at_css("platform").content
      assert_equal ">= 2.6.3", @xml.at_css("rubygems-version").content
      assert_equal ">= 2.0.0", @xml.at_css("ruby-version").content
      assert_equal "false", @xml.at_css("prerelease").content
      assert_equal "MIT", @xml.at_css("licenses").content
      assert_equal "Opencv", @xml.at_css("requirements").content
      assert_equal "b5d4045c3f466fa91fe2cc6abe79232a1a57cdf104f7a26e716e0a1e2789df78", @xml.at_css("sha").content
    end
  end

  context 'YAML' do
    setup do
      serializer = VersionSerializer.new(@version)
      yaml_version = serializer.to_yaml

      @yaml = YAML.load(yaml_version)
    end
    should 'have proper hash keys' do
      assert_equal %w(
        authors
        built_at
        created_at
        description
        downloads_count
        licenses
        metadata
        number
        platform
        prerelease
        requirements
        ruby_version
        rubygems_version
        sha
        summary
      ), @yaml.keys.sort
    end

    should 'display correct data' do
      expected_hash = {
        "authors" => "Joe User",
        "built_at" => Time.utc(2016, 05, 04),
        "created_at" => Time.utc(2016, 05, 04),
        "description" => "Some awesome gem",
        "downloads_count" => 0,
        "metadata" => { "foo" => "bar" },
        "number" => "1.0.1",
        "summary" => nil,
        "platform" => "ruby",
        "rubygems_version" => ">= 2.6.3",
        "ruby_version" => ">= 2.0.0",
        "prerelease" => false,
        "licenses" => "MIT",
        "requirements" => "Opencv",
        "sha" => "b5d4045c3f466fa91fe2cc6abe79232a1a57cdf104f7a26e716e0a1e2789df78"
      }

      assert_equal expected_hash, @yaml
    end
  end
end
