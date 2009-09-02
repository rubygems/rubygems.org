require 'test_helper'

class TestGenerator < Test::Unit::TestCase
  def build_generator(testing_framework = nil, options = {})
    stub(Git).global_config() do
      {'user.name' => 'John Doe', 'user.email' => 'john@example.com', 'github.user' => 'johndoe', 'github.token' => 'yyz'}
    end

    options[:testing_framework] = testing_framework
    Jeweler::Generator.new('the-perfect-gem', options)
  end

  context "initialize" do
    should "raise error if nil repo name given" do
      assert_raise Jeweler::NoGitHubRepoNameGiven do
        Jeweler::Generator.new(nil)
      end
    end

    should "raise error if blank repo name given" do
      assert_raise Jeweler::NoGitHubRepoNameGiven do
        Jeweler::Generator.new("")
      end
    end

    should "have shoulda as default framework" do
      assert_equal :shoulda, build_generator.testing_framework
    end

    should "have repository name as default target dir" do
      assert_equal 'the-perfect-gem', build_generator.target_dir
    end

    should "have default summary" do
      assert_equal "TODO: one-line summary of your gem", build_generator.summary
    end

    should "have default description" do
      assert_equal "TODO: longer description of your gem", build_generator.description
    end

    should "not create repo by default" do
      assert ! build_generator.should_create_repo
    end

    should "not use cucumber by default" do
      assert ! build_generator.should_use_cucumber
    end

    should "not use reek by default" do
      assert ! build_generator.should_use_reek
    end

    should "not use roodi by default" do
      assert ! build_generator.should_use_roodi
    end

    should "raise error for invalid testing frameworks" do
      assert_raise ArgumentError do
        build_generator(:zomg_invalid)
      end
    end
  end

  should "have the correct git remote" do
    assert_equal 'git@github.com:johndoe/the-perfect-gem.git', build_generator.git_remote
  end

  should "have the correct project homepage" do
    assert_equal 'http://github.com/johndoe/the-perfect-gem', build_generator.project_homepage
  end

  should "have the correct constant name" do
    assert_equal "ThePerfectGem", build_generator.constant_name
  end

  should "have the correct file name prefix" do
    assert_equal "the_perfect_gem", build_generator.file_name_prefix
  end

  should "have the correct require name" do
    assert_equal "the-perfect-gem", build_generator.require_name
  end

  should "have the correct lib file name" do
    assert_equal "the-perfect-gem.rb", build_generator.lib_filename
  end

  def self.should_have_generator_attribute(attribute, value)
    should "have #{value} for #{attribute}" do
      assert_equal value, build_generator(@framework).send(attribute)
    end
  end

  context "shoulda" do
    setup { @framework = :shoulda }
    should_have_generator_attribute :test_task, 'test'
    should_have_generator_attribute :test_dir, 'test'
    should_have_generator_attribute :default_task, 'test'
    should_have_generator_attribute :feature_support_require, 'test/unit/assertions'
    should_have_generator_attribute :feature_support_extend, 'Test::Unit::Assertions'
    should_have_generator_attribute :test_pattern, 'test/**/*_test.rb'
    should_have_generator_attribute :test_filename, 'the-perfect-gem_test.rb'
    should_have_generator_attribute :test_helper_filename, 'test_helper.rb'
  end

  context "testunit" do
    setup { @framework = :testunit }
    should_have_generator_attribute :test_task, 'test'
    should_have_generator_attribute :test_dir, 'test'
    should_have_generator_attribute :default_task, 'test'
    should_have_generator_attribute :feature_support_require, 'test/unit/assertions'
    should_have_generator_attribute :feature_support_extend, 'Test::Unit::Assertions'
    should_have_generator_attribute :test_pattern, 'test/**/*_test.rb'
    should_have_generator_attribute :test_filename, 'the-perfect-gem_test.rb'
    should_have_generator_attribute :test_helper_filename, 'test_helper.rb'
  end

  context "minitest" do
    setup { @framework = :minitest }
    should_have_generator_attribute :test_task, 'test'
    should_have_generator_attribute :test_dir, 'test'
    should_have_generator_attribute :default_task, 'test'
    should_have_generator_attribute :feature_support_require, 'mini/test'
    should_have_generator_attribute :feature_support_extend, 'Mini::Test::Assertions'
    should_have_generator_attribute :test_pattern, 'test/**/*_test.rb'
    should_have_generator_attribute :test_filename, 'the-perfect-gem_test.rb'
    should_have_generator_attribute :test_helper_filename, 'test_helper.rb'
  end

  context "bacon" do
    setup { @framework = :bacon }
    should_have_generator_attribute :test_task, 'spec'
    should_have_generator_attribute :test_dir, 'spec'
    should_have_generator_attribute :default_task, 'spec'
    should_have_generator_attribute :feature_support_require, 'test/unit/assertions'
    should_have_generator_attribute :feature_support_extend, 'Test::Unit::Assertions'
    should_have_generator_attribute :test_pattern, 'spec/**/*_spec.rb'
    should_have_generator_attribute :test_filename, 'the-perfect-gem_spec.rb'
    should_have_generator_attribute :test_helper_filename, 'spec_helper.rb'
  end

  context "rspec" do
    setup { @framework = :rspec }
    should_have_generator_attribute :test_task, 'spec'
    should_have_generator_attribute :test_dir, 'spec'
    should_have_generator_attribute :default_task, 'spec'
    should_have_generator_attribute :feature_support_require, 'spec/expectations'
    should_have_generator_attribute :feature_support_extend, nil
    should_have_generator_attribute :test_pattern, 'spec/**/*_spec.rb'
    should_have_generator_attribute :test_filename, 'the-perfect-gem_spec.rb'
    should_have_generator_attribute :test_helper_filename, 'spec_helper.rb'
  end

  context "micronaut" do
    setup { @framework = :micronaut }
    should_have_generator_attribute :test_task, 'examples'
    should_have_generator_attribute :test_dir, 'examples'
    should_have_generator_attribute :default_task, 'examples'
    should_have_generator_attribute :feature_support_require, 'micronaut/expectations'
    should_have_generator_attribute :feature_support_extend, 'Micronaut::Matchers'
    should_have_generator_attribute :test_pattern, 'examples/**/*_example.rb'
    should_have_generator_attribute :test_filename, 'the-perfect-gem_example.rb'
    should_have_generator_attribute :test_helper_filename, 'example_helper.rb'
  end
end
