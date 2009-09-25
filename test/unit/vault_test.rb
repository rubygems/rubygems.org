require File.dirname(__FILE__) + '/../test_helper'

class VaultTest < ActiveSupport::TestCase
  def setup
    `git clean -dfx server/; git checkout server/`
    Gemcutter.indexer.generate_index
  end

  context "with a filesystem vault" do
    setup do
      @rubygem = Rubygem.new
      @spec = gem_spec

      class TestFS
        include Vault::FS
      end
      @vault = TestFS.new
      stub(@vault).rubygem { @rubygem }
      stub(@vault).spec { @spec }
      stub(@vault).body { StringIO.new("lots of data") }
    end

    context "loading source index" do
      setup do
        @path = Gemcutter.server_path("source_index")
        @source_index = "source_index"
      end

      should "load up the source index from the file system" do
        stub(File).exists?(@path) { true }

        zipped = "zipped"
        marshalled = "marshalled"

        mock(File).read(@path) { zipped }
        mock(Gem).inflate(zipped) { marshalled }
        mock(Marshal).load(marshalled) { @source_index }

        assert_equal @source_index, @vault.source_index
      end

      should "create a new source index if it's not there" do
        stub(File).exists?(@path) { false }
        stub(Gem::SourceIndex).new { @source_index }
        assert_equal @source_index, @vault.source_index
      end
    end

    should "write the gem" do
      @vault.write_gem

      cache_path = Gemcutter.server_path("gems", "#{@spec.original_name}.gem")
      assert File.exists?(cache_path)
      assert_equal 0100644, File.stat(cache_path).mode

      quick_path = Gemcutter.server_path("quick", "Marshal.#{Gem.marshal_version}", "#{@spec.original_name}.gemspec.rz")
      assert File.exists?(quick_path)
      assert_equal 0100644, File.stat(quick_path).mode

      quick_gem_data = File.open(quick_path, 'rb') { |f| Marshal.load(Gem.inflate(f.read)) }
      Gemcutter.indexer.abbreviate @spec
      Gemcutter.indexer.sanitize @spec
      assert_equal @spec, quick_gem_data
    end

    should "update the index" do
      @vault.update_index

      source_index = Gemcutter.server_path("source_index")
      assert File.exists?(source_index)

      source_index_data = File.open(source_index) { |f| Marshal.load(Gem.inflate(f.read)) }
      assert source_index_data.gems.has_key?(@spec.original_name)

      latest_specs = Gemcutter.server_path("latest_specs.4.8")
      assert File.exists?(latest_specs)

      latest_specs_data = File.open(latest_specs) { |f| Marshal.load f.read }
      assert_equal 1, latest_specs_data.size
      assert_equal ["test", Gem::Version.new("0.0.0"), "ruby"], latest_specs_data.first
    end
  end

  context "with an amazon s3 vault" do
    setup do
      @vault = stub!
      @vault.include Vault::S3
    end

    should "respond to store" do
      @vault.respond_to?(:store)
    end
  end
end
