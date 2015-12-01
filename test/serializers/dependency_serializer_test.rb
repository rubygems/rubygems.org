require 'test_helper'

class DependencySerializerTest < ActiveSupport::TestCase
  setup do
    @version = create(:version)
    @dependency = build(:dependency, version: @version)
  end

  context 'JSON' do
    should 'have proper hash keys' do
      @serializer = DependencySerializer.new(@dependency)
      @json_dependency = @serializer.attributes

      assert_equal(
        @json_dependency.keys,
        [:name, :requirements]
      )
    end

    should 'display correct data' do
      @serializer = DependencySerializer.new(@dependency)
      @json_dependency = @serializer.attributes

      assert_equal(
        @json_dependency,
        {
          name: @dependency.name,
          requirements: @dependency.requirements
        }
      )
    end
  end

  context 'XML' do
    should 'have proper hash keys' do
      @serializer = DependencySerializer.new(@dependency)
      @xml_dependency = @serializer.to_xml
      xml = Nokogiri.parse(@xml_dependency)

      assert_equal %w(name requirements), xml.root.children.select(&:element?).map(&:name).sort
    end

    should 'display correct data' do
      @serializer = DependencySerializer.new(@dependency)
      @xml_dependency = @serializer.to_xml

      xml = Nokogiri.parse(@xml_dependency)

      assert_equal "dependency", xml.root.name
      assert_equal %w(name requirements), xml.root.children.select(&:element?).map(&:name).sort
      assert_equal @dependency.rubygem.name, xml.at_css("name").content

      if @dependency.requirements.nil?
        assert_equal '', xml.at_css("requirements").content
      else
        assert_equal @dependency.requirements, xml.at_css("requirements").content
      end
    end
  end

  context 'YAML' do
    should 'have proper hash keys' do
      @serializer = DependencySerializer.new(@dependency)
      @yaml_dependency = @serializer.to_yaml

      yaml = YAML.load(@yaml_dependency)

      assert_equal %w(name requirements), yaml.keys.sort
    end

    should 'display correct data' do
      @serializer = DependencySerializer.new(@dependency)
      @yaml_dependency = @serializer.to_yaml

      assert_equal(
        YAML.load(@yaml_dependency),
        {
          "name" => @dependency.rubygem.name,
          'requirements' => @dependency.requirements
        }
      )
    end
  end
end
