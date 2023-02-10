require "test_helper"

class GemDependentTest < ActiveSupport::TestCase
  context "creating a new dependency_api" do
    setup do
      @gem = create(:rubygem)
      @gem_dependent = GemDependent.new(@gem.name)
    end

    should "have some state" do
      assert_respond_to @gem_dependent, :gem_names
    end
  end

  context "no gem_names" do
    should "return an ArgumentError" do
      assert_raises ArgumentError do
        GemDependent.new.to_a
      end
    end
  end

  context "with gem_names" do
    setup do
      rack2 = create(:rubygem, name: "rack2")
      create(:version, number: "0.0.1", rubygem: rack2)
    end

    should "return rack2" do
      result = {
        name:                "rack2",
        number:              "0.0.1",
        platform:            "ruby",
        dependencies: []
      }

      deps = GemDependent.new(["rack2"]).to_a
      result.each_pair do |k, v|
        assert_equal v, deps.first[k]
      end
    end

    context "multiple versions" do
      setup do
        rack = create(:rubygem, name: "rack")
        create(:version, number: "0.2.2", rubygem: rack)
        create(:version, number: "0.1.2", rubygem: rack)
        create(:version, number: "0.1.2", platform: "jruby", rubygem: rack)
        create(:version, number: "0.1.3", rubygem: rack)
      end

      should "return all versions and platform" do
        result = [["0.1.3", "ruby"], ["0.1.2", "ruby"], ["0.1.2", "jruby"], ["0.2.2", "ruby"]]

        deps = GemDependent.new(["rack"]).to_a
        deps.map { |x| [x[:number], x[:platform]] }.each do |dep|
          assert_includes result, dep
        end
      end
    end

    context "has dependencies" do
      setup do
        devise = create(:rubygem, name: "devise")
        version = create(:version, number: "1.0.0", rubygem: devise)

        %w[foo bar].map do |gem_name|
          create(:rubygem, name: gem_name).tap do |rubygem|
            gem_dependency = Gem::Dependency.new(rubygem.name, [">= 0.0.0"])
            create(:dependency, rubygem: rubygem, version: version, gem_dependency: gem_dependency)
          end
        end
      end

      should "return dependencies" do
        expected_deps = [["foo", ">= 0.0.0"], ["bar", ">= 0.0.0"]]

        dep = GemDependent.new(["devise"]).to_a.first
        assert_equal "devise", dep[:name]
        assert_equal "1.0.0", dep[:number]

        expected_deps.each do |expected_dep|
          assert_includes dep[:dependencies], expected_dep
        end
      end
    end

    context "non indexed versions" do
      setup do
        nokogiri = create(:rubygem, name: "nokogiri")
        create(:version, number: "0.0.1", rubygem: nokogiri)
        create(:version, number: "0.1.1", rubygem: nokogiri, indexed: false)
      end

      should "filter non indexed version" do
        result = {
          name: "nokogiri",
          number: "0.0.1",
          platform: "ruby",
          dependencies: []
        }

        deps = GemDependent.new(["nokogiri"]).to_a
        assert_equal [result], deps
      end
    end
  end

  context "with gem_names which do not exist" do
    should "return empty array" do
      assert_empty GemDependent.new(["does_not_exist"]).to_a
    end
  end
end
