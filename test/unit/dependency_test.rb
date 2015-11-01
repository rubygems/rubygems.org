require 'test_helper'

class DependencyTest < ActiveSupport::TestCase
  should belong_to :rubygem
  should belong_to :version

  context "with dependency" do
    setup do
      @version = create(:version)
      @dependency = build(:dependency, version: @version)
    end

    should "be valid with factory" do
      assert @dependency.valid?
    end

    should "return JSON" do
      @dependency.save
      json = MultiJson.load(@dependency.to_json)

      assert_equal %w(name requirements), json.keys.sort
      assert_equal @dependency.rubygem.name, json["name"]
      assert_equal @dependency.requirements, json["requirements"]
    end

    should "return XML" do
      @dependency.save
      xml = Nokogiri.parse(@dependency.to_xml)

      assert_equal "dependency", xml.root.name
      assert_equal %w(name requirements), xml.root.children.select(&:element?).map(&:name).sort
      assert_equal @dependency.rubygem.name, xml.at_css("name").content
      assert_equal @dependency.requirements, xml.at_css("requirements").content
    end

    should "return YAML" do
      @dependency.save
      yaml = YAML.load(@dependency.to_yaml)

      assert_equal %w(name requirements), yaml.keys.sort
      assert_equal @dependency.rubygem.name, yaml["name"]
      assert_equal @dependency.requirements, yaml["requirements"]
    end

    should "be pushed onto a redis list if a runtime dependency" do
      @dependency.save

      assert_equal "#{@dependency.name} #{@dependency.requirements}",
        Redis.current.lindex(Dependency.runtime_key(@version.full_name), 0)
    end

    should "not push development dependency onto the redis list" do
      @dependency = create(:development_dependency)

      assert !Redis.current.exists(Dependency.runtime_key(@dependency.version.full_name))
    end
  end

  context "with a Gem::Dependency" do
    context "that refers to a Rubygem that exists with a malformed dependency" do
      setup do
        @rubygem        = create(:rubygem)
        @requirements   = ['= 0.0.0']
        @gem_dependency = Gem::Dependency.new(@rubygem.name, @requirements)
      end

      should "correctly create a Dependency referring to the existing Rubygem" do
        @gem_dependency.stubs(:requirements_list)
          .returns(['#<YAML::Syck::DefaultKey:0x0000000> 0.0.0'])
        @dependency = create(:dependency, rubygem: @rubygem, gem_dependency: @gem_dependency)

        assert_equal @rubygem, @dependency.rubygem
        assert_equal @requirements[0].to_s, @dependency.requirements
      end

      should "correctly display a malformed Dependency referring to the existing Rubygem" do
        @dependency = create(:dependency, rubygem: @rubygem, gem_dependency: @gem_dependency)
        @dependency.stubs(:requirements).returns '#<YAML::Syck::DefaultKey:0x0000000> 0.0.0'

        assert_equal @rubygem, @dependency.rubygem
        assert_equal @requirements[0].to_s, @dependency.clean_requirements
      end
    end

    context "that refers to a Rubygem that exists" do
      setup do
        @rubygem        = create(:rubygem)
        @requirements   = ['>= 0.0.0']
        @gem_dependency = Gem::Dependency.new(@rubygem.name, @requirements)
        @dependency     = create(:dependency, rubygem: @rubygem, gem_dependency: @gem_dependency)
      end

      should "create a Dependency referring to the existing Rubygem" do
        assert_equal @rubygem, @dependency.rubygem
        assert_equal @requirements[0].to_s, @dependency.requirements
      end
    end

    context "that refers to a Rubygem that exists and has multiple requirements" do
      setup do
        @rubygem        = create(:rubygem)
        @requirements   = ['< 1.0.0', '>= 0.0.0']
        @gem_dependency = Gem::Dependency.new(@rubygem.name, @requirements)
        @dependency     = create(:dependency, rubygem: @rubygem, gem_dependency: @gem_dependency)
      end

      should "create a Dependency referring to the existing Rubygem" do
        assert_equal @rubygem, @dependency.rubygem
        assert_equal @requirements.join(', '), @dependency.requirements
      end
    end

    context "that refers to a Rubygem that does not exist" do
      setup do
        @specification = gem_specification_from_gem_fixture('with_dependencies-0.0.0')
        @rubygem       = Rubygem.new(name: @specification.name)
        @version       = @rubygem.find_or_initialize_version_from_spec(@specification)
        @version.sha256 = "dummy"

        @rubygem.update_attributes_from_gem_specification!(@version, @specification)

        @rubygem_name   = 'other-name'
        @gem_dependency = Gem::Dependency.new(@rubygem_name, "= 1.0.0")
      end

      should "create a Dependency but not a rubygem" do
        dependency = Dependency.create(gem_dependency: @gem_dependency, version: @version)
        assert !dependency.new_record?
        assert !dependency.errors[:base].present?
        assert_nil Rubygem.find_by(name: @rubygem_name)

        assert_equal "other-name", dependency.unresolved_name
        assert_equal "other-name", dependency.name
      end
    end
  end

  context "without using Gem::Dependency" do
    should "be invalid" do
      dependency = Dependency.create(gem_dependency: ["ruby-ajp", ">= 0.2.0"])
      assert dependency.new_record?
      assert dependency.errors[:rubygem].present?
    end
  end

  context "with a Gem::Dependency for with a blank name" do
    setup do
      @gem_dependency = Gem::Dependency.new("", "= 1.0.0")
    end

    should "not create a Dependency" do
      dependency = Dependency.create(gem_dependency: @gem_dependency)
      assert dependency.new_record?
      assert dependency.errors[:rubygem].present?
      assert_nil Rubygem.find_by(name: "")
    end
  end

  context "yaml" do
    setup do
      create(:rubygem)
      @dependency = create(:dependency)
    end

    should "return its payload" do
      assert_equal @dependency.payload, YAML.load(@dependency.to_yaml)
    end

    should "nest properly" do
      assert_equal [@dependency.payload], YAML.load([@dependency].to_yaml)
    end
  end
end
