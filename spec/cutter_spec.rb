require File.join(File.dirname(__FILE__), 'spec_helper')

describe Gem::Cutter do
  before do
    @gem = "test-0.0.0.gem"
    @gem_file = gem_file(@gem)
    @cache_path = Gem::Cutter.server_path("cache", @gem)
    @spec_path = Gem::Cutter.server_path("specifications", @gem + "spec")

    FileUtils.rm_rf Dir["server/cache/*", "server/*specs*", "server/quick", "server/specifications/*"]
    Gem::Cutter.indexer.generate_index
  end

  describe "with a new gem" do
    before do
      @cutter = Gem::Cutter.new(@gem_file)
      @temp_path = "temp path"
      stub(Tempfile).new("gem").stub!.path { @temp_path }
      stub(File).open(@temp_path, 'wb')
      stub(File).size(@temp_path) { 42 }
    end

    it "should store data" do
      @cutter.data.should == @gem_file
    end

    it "should not save an empty gem" do
      mock(File).size(@temp_path) { 0 }

      @cutter.save_gem

      File.exists?(@cache_path).should be_false
      File.exists?(@spec_path).should be_false
      @cutter.error.should == "Empty gem cannot be processed."
    end

    it "should create quick index file when saving" do
      spec = "spec"
      stub(Gem::Format).from_file_by_path(@temp_path).stub!.spec { spec }
      stub(spec).to_ruby
      stub(spec).name { "test" }
      stub(spec).version { "0.0.0" }

      mock(FileUtils).cp(@temp_path, @cache_path)
      mock(File).open(@spec_path, 'w')

      mock(Gem::Cutter).indexer.stub!.abbreviate(spec)
      mock(Gem::Cutter).indexer.stub!.sanitize(spec)

      marshal = "marshal"
      quick_path = Gem::Cutter.server_path("quick", "Marshal.#{Gem.marshal_version}", "#{spec.name}-#{spec.version}.gemspec.rz")

      mock(Marshal).dump(spec) { marshal }
      mock(Gem).deflate(marshal)
      mock(File).open(quick_path, 'wb')

      @cutter.save_gem
    end

    it "should save gem and update index" do
      #@cutter.save_gem
#      File.exists?(@cache_path).should be_true
#      File.exists?(@spec_path).should be_true
#      FileUtils.compare_file(@gem_file.path, @cache_path).should be_true
    end
  end

  describe "with an existing gem" do
    before do
      @gem_up = "test-0.0.0.gem_up"
      @gem_up_file = gem_file(@gem_up)
      @cutter = Gem::Cutter.new(@gem_up_file)

      FileUtils.cp @gem_file.path, @cache_path
      spec = Gem::Installer.new(@cache_path, :unpack => true).spec.to_ruby
      File.open(@spec_path, "w") { |f| f.write spec }
    end

    it "should save gem and update index" do
      @cutter.save_gem
      File.exists?(@cache_path).should be_true
      File.exists?(@spec_path).should be_true
      FileUtils.compare_file(@gem_up_file.path, @cache_path).should be_true
    end
  end
end
