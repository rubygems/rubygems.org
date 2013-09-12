require 'test_helper'

class TreeTest < ActiveSupport::TestCase
  
  setup do
    @rubygem = create(:rubygem, :name => "phocoder-rb")
    @version = create(:version, :rubygem => @rubygem, :number => "0.1.7")
    @tree = Tree.create! :version => @version
    
    @data_json = [
        {"name"=>"i18n",
        "version"=>"0.6.1",
        "dependencies"=>
         [{"name"=>"activesupport",
           "requirement"=>"~> 3.0.0",
           "type"=>"development"},
          {"name"=>"sqlite3", "requirement"=>">= 0", "type"=>"development"},
          {"name"=>"mocha", "requirement"=>">= 0", "type"=>"development"},
          {"name"=>"test_declarative",
           "requirement"=>">= 0",
           "type"=>"development"}]},
       {"name"=>"multi_json",
        "version"=>"1.6.1",
        "dependencies"=>
         [{"name"=>"bundler", "requirement"=>"~> 1.0", "type"=>"development"}]},
       {"name"=>"activesupport",
        "version"=>"3.2.12",
        "dependencies"=>
         [{"name"=>"i18n", "requirement"=>"~> 0.6", "type"=>"runtime"},
          {"name"=>"multi_json", "requirement"=>"~> 1.0", "type"=>"runtime"}]},
       {"name"=>"builder", "version"=>"3.1.4", "dependencies"=>[]},
       {"name"=>"phocoder-rb",
        "version"=>"0.1.7",
        "dependencies"=>
         [{"name"=>"activesupport", "requirement"=>"> 3.0.0", "type"=>"runtime"},
          {"name"=>"i18n", "requirement"=>">= 0", "type"=>"runtime"},
          {"name"=>"builder", "requirement"=>">= 0", "type"=>"runtime"}]},
       {"name"=>"bundler",
        "version"=>"1.3.0.pre.5",
        "dependencies"=>
         [{"name"=>"ronn", "requirement"=>">= 0", "type"=>"development"},
          {"name"=>"rspec", "requirement"=>"~> 2.11", "type"=>"development"}]}
      ].to_json
  end

  context "tmpdir" do
    should "== /tmp/@tree.id" do
      assert_equal "/tmp/#{@tree.id}", @tree.tmpdir
    end
  end

  context "create_tmpdir" do
    should "create a directory at /tmp/test_id" do
      tmpdir = "/tmp/#{@tree.id}"
      assert !File.exists?(tmpdir)
      @tree.create_tmpdir
      assert File.exists?(tmpdir)
      FileUtils.rm_r(tmpdir)
    end
  end


  context "gemfile_string" do
    should "produce a valid string" do
      assert_equal %[source 'https://rubygems.org'\ngem '#{@version.rubygem.name}', '#{@version.number}'], @tree.gemfile_string
    end
  end

  context "gemfile_path" do
    should "== /tmp/@test.id/Gemfile" do
      assert_equal "/tmp/#{@tree.id}/Gemfile", @tree.gemfile_path
    end
  end

  context "write_gemfile" do
    should "write a valid Gemfile" do
      assert !File.exists?(@tree.gemfile_path)
      @tree.write_gemfile
      assert File.exists?(@tree.gemfile_path)
      assert_equal File.open(@tree.gemfile_path).read, @tree.gemfile_string
      FileUtils.rm_r(@tree.tmpdir)
    end
  end

  # NOTE : This test actually shells out and runs 'bundle install'
  # It will fail if there are network troubles or if rubygems.org is down.
  # Yes, it's kinda weird...
  context "prep_data" do
    should "return true and set the data attribute with some JSON" do
      success = @tree.prep_data
      assert success

      data = JSON(@tree.data)
      assert_equal 10, data.length
    end
  end

  context "keyed_specs" do
    setup do
      @tree.data = @data_json
    end
    should "return a hash" do
      keyed_specs = @tree.keyed_specs
      assert_not_nil keyed_specs
      assert keyed_specs.is_a?(Hash)
      assert keyed_specs['phocoder-rb'].is_a?(Hash)
    end
  end

  context "translate_specs" do

    setup do
      @tree.data = @data_json
    end

    should "return the dependency list massaged into a tree" do
      tree_data = @tree.translate_specs
      assert_not_nil tree_data
    end

    should "set the runtime_weight" do
      @tree.translate_specs
      assert_equal 4, @tree.runtime_weight
    end

    should "set the development_weight" do
      @tree.translate_specs
      assert_equal 6, @tree.development_weight
    end

  end

end
