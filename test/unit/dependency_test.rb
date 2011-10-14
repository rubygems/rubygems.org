require File.dirname(__FILE__) + '/../test_helper'

class DependencyTest < ActiveSupport::TestCase
  should belong_to :rubygem
  should belong_to :version

  context "with dependency" do
    setup do
      @version = Factory(:version)
      @dependency = FactoryGirl.build(:dependency, :version => @version)
    end

    should "be valid with factory" do
      assert_valid @dependency
    end

    should "return JSON" do
      @dependency.save
      json = MultiJson.decode(@dependency.to_json)

      assert_equal %w[name requirements], json.keys.sort
      assert_equal @dependency.rubygem.name, json["name"]
      assert_equal @dependency.requirements, json["requirements"]
    end

    should "return XML" do
      @dependency.save
      xml = Nokogiri.parse(@dependency.to_xml)

      assert_equal "dependency", xml.root.name
      assert_equal %w[name requirements], xml.root.children.select(&:element?).map(&:name).sort
      assert_equal @dependency.rubygem.name, xml.at_css("name").content
      assert_equal @dependency.requirements, xml.at_css("requirements").content
    end

    should "return YAML" do
      @dependency.save
      yaml = YAML.load(@dependency.to_yaml)

      assert_equal %w[name requirements], yaml.keys.sort
      assert_equal @dependency.rubygem.name, yaml["name"]
      assert_equal @dependency.requirements, yaml["requirements"]
    end

    should "be pushed onto a redis list if a runtime dependency" do
      @dependency.save

      assert_equal "#{@dependency.name} #{@dependency.requirements}", $redis.lindex(Dependency.runtime_key(@version.full_name), 0)
    end

    should "not push development dependency onto the redis list" do
      @dependency = Factory(:development_dependency)

      assert !$redis.exists(Dependency.runtime_key(@dependency.version.full_name))
    end
  end

  context "with a Gem::Dependency" do
    context "that refers to a Rubygem that exists with a malformed dependency" do
      setup do
        @rubygem        = Factory(:rubygem)
        @requirements   = ['= 0.0.0']
        @gem_dependency = Gem::Dependency.new(@rubygem.name, @requirements)
      end

      should "correctly create a Dependency referring to the existing Rubygem" do
        stub(@gem_dependency).requirements_list { ['#<YAML::Syck::DefaultKey:0x0000000> 0.0.0'] }
        @dependency = Factory(:dependency, :rubygem => @rubygem, :gem_dependency => @gem_dependency)

        assert_equal @rubygem, @dependency.rubygem
        assert_equal @requirements[0].to_s, @dependency.requirements
      end

      should "correctly display a malformed Dependency referring to the existing Rubygem" do
        @dependency = Factory(:dependency, :rubygem => @rubygem, :gem_dependency => @gem_dependency)
        stub(@dependency).requirements { '#<YAML::Syck::DefaultKey:0x0000000> 0.0.0' }

        assert_equal @rubygem, @dependency.rubygem
        assert_equal @requirements[0].to_s, @dependency.clean_requirements
      end
    end

    context "that refers to a Rubygem that exists" do
      setup do
        @rubygem        = Factory(:rubygem)
        @requirements   = ['>= 0.0.0']
        @gem_dependency = Gem::Dependency.new(@rubygem.name, @requirements)
        @dependency     = Factory(:dependency, :rubygem => @rubygem, :gem_dependency => @gem_dependency)
      end

      should "create a Dependency referring to the existing Rubygem" do
        assert_equal @rubygem,      @dependency.rubygem
        assert_equal @requirements[0].to_s, @dependency.requirements
      end
    end

    context "that refers to a Rubygem that exists and has multiple requirements" do
      setup do
        @rubygem        = Factory(:rubygem)
        @requirements   = ['< 1.0.0', '>= 0.0.0']
        @gem_dependency = Gem::Dependency.new(@rubygem.name, @requirements)
        @dependency     = Factory(:dependency, :rubygem => @rubygem, :gem_dependency => @gem_dependency)
      end

      should "create a Dependency referring to the existing Rubygem" do
        assert_equal @rubygem, @dependency.rubygem
        assert_equal @requirements.join(', '), @dependency.requirements
      end
    end

    context "that refers to a Rubygem that does not exist" do
      setup do
        @rubygem_name   = 'other-name'
        @gem_dependency = Gem::Dependency.new(@rubygem_name, "= 1.0.0")
      end

      should "not create rubygem" do
        dependency = Dependency.create(:gem_dependency => @gem_dependency)
        assert dependency.new_record?
        assert dependency.errors[:base].present?
        assert_nil Rubygem.find_by_name(@rubygem_name)
      end
    end
  end

  context "without using Gem::Dependency" do
    should "be invalid" do
      dependency = Dependency.create(:gem_dependency => ["ruby-ajp", ">= 0.2.0"])
      assert dependency.new_record?
      assert dependency.errors[:rubygem].present?
    end
  end

  context "yaml" do
    setup do
      Factory(:rubygem)
      @dependency = Factory(:dependency)
    end

    should "return its payload" do
      assert_equal @dependency.payload, YAML.load(@dependency.to_yaml)
    end

    should "nest properly" do
      assert_equal [@dependency.payload], YAML.load([@dependency].to_yaml)
    end
  end
end
