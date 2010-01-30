require File.dirname(__FILE__) + '/../test_helper'

class DependencyTest < ActiveSupport::TestCase
  should_belong_to :rubygem
  should_belong_to :version
  should_validate_presence_of :requirements

  context "with dependency" do
    setup do
      @dependency = Factory.build(:dependency)
    end

    should "be valid with factory" do
      assert_valid @dependency
    end

    should "return json" do
      json = JSON.parse(@dependency.to_json)

      assert_equal %w[name requirements], json.keys
      assert_equal @dependency.rubygem.name, json["name"]
      assert_equal @dependency.requirements, json["requirements"]
    end

    should "return xml" do
      xml = Nokogiri.parse(@dependency.to_xml)

      assert_equal "dependency", xml.root.name
      assert_equal %w[name requirements], xml.root.children.select(&:element?).map(&:name)
      assert_equal @dependency.rubygem.name, xml.at_css("name").content
      assert_equal @dependency.requirements, xml.at_css("requirements").content
    end
  end

  context "with a Gem::Dependency" do
    context "that refers to a Rubygem that exists" do
      setup do
        @rubygem        = Factory(:rubygem)
        @requirements   = ['>= 0.0.0']
        @gem_dependency = gem_dependency_stub(@rubygem.name, @requirements)
        @dependency     = Dependency.create_from_gem_dependency!(@gem_dependency)
      end

      should "create a Dependency referring to the existing Rubygem" do
        assert_equal @rubygem,      @dependency.rubygem
        assert_equal @requirements.to_s, @dependency.requirements
      end
    end

    context "that refers to a Rubygem that exists and has multiple requirements" do
      setup do
        @rubygem        = Factory(:rubygem)
        @requirements   = ['>= 0.0.0', '< 1.0.0']
        @gem_dependency = gem_dependency_stub(@rubygem.name, @requirements)
        @dependency     = Dependency.create_from_gem_dependency!(@gem_dependency)
      end

      should "create a Dependency referring to the existing Rubygem" do
        assert_equal @rubygem,            @dependency.rubygem
        assert_equal @requirements.join(', '), @dependency.requirements
      end
    end

    context "that refers to a Rubygem that does not exist" do
      setup do
        @rubygem_name   = 'other-name'
        @gem_dependency = gem_dependency_stub(@rubygem_name)
        @dependency     = Dependency.create_from_gem_dependency!(@gem_dependency)
      end

      should_change("the existence of the rubygem", :from => false, :to => true) do
        Rubygem.find_by_name(@rubygem_name).present?
      end
    end
  end

  context "with a bad gem dependency" do
    should "not fail" do
      assert_nothing_raised do
        Dependency.create_from_gem_dependency!(["ruby-ajp", ">= 0.2.0"])
      end
    end
  end
end
