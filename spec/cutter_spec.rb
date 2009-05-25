require File.join(File.dirname(__FILE__), 'spec_helper')

describe Gem::Cutter do
  def stub_spec
    @spec = "spec"

    stub(Gem::Format).from_file_by_path(@temp_path).stub!.spec { @spec }
    stub(@spec).to_ruby
    stub(@spec).name { "test" }
    stub(@spec).version { "0.0.0" }
    stub(@spec).dependencies { [] }

    # Working around a horrible RR bug
    def @spec.original_name() end;
    #stub(@spec).original_name { "test-0.0.0" }
  end

  def mock_save_and_index
    mock(FileUtils).cp(@temp_path, @cache_path)
    mock(File).chmod(0644, @cache_path)
    mock(File).open(@spec_path, 'w')

    index = "index"
    mock(Gem::SourceIndex).new { index }
    mock(index).add_spec(@spec, @spec.original_name)

    mock(Gem::Cutter).indexer.stub!.abbreviate(@spec)
    mock(Gem::Cutter).indexer.stub!.sanitize(@spec)

    marshal = "marshal"
    quick_path = Gemcutter.server_path("quick", "Marshal.#{Gem.marshal_version}", "#{@spec.original_name}.gemspec.rz")

    mock(Marshal).dump(@spec) { mock(Gem).deflate(stub!) }
    mock(File).open(quick_path, 'wb')
  end

  before do
    @gem = "test-0.0.0.gem"
    @gem_file = gem_file(@gem)
    @gem_up = "test-0.0.0.gem_up"
    @gem_up_file = gem_file(@gem_up)
    @cache_path = Gemcutter.server_path("cache", @gem)
    @spec_path = Gemcutter.server_path("specifications", @gem + "spec")
    @temp_path = "temp path"

    regenerate_index

    stub(Tempfile).new("gem").stub!.path { @temp_path }
    stub(File).exists?(Gemcutter.server_path("source_index")) { false }
    stub(File).exists?(@cache_path) { false }
    stub(File).exists?(@spec_path) { false }
    stub(File).open(@temp_path, 'wb')
    stub(File).open(Gemcutter.server_path("source_index"), 'wb')
    stub(File).size(@temp_path) { 42 }
  end

  describe "with a new gem" do
    before do
      @cutter = Gem::Cutter.new(@gem_file)
    end

    it "should store data" do
      @cutter.data.should == @gem_file
    end

    it "should not save an empty gem" do
      stub(File).size(@temp_path) { 0 }
      mock(@cutter).save.never
      mock(@cutter).index.never

      @cutter.process
      @cutter.spec.should be_nil
      @cutter.error.should == "Empty gem cannot be processed."
    end

    it "should create quick index file when saving" do
      stub_spec
      mock_save_and_index

      @cutter.process
      @cutter.spec.should == @spec
      @cutter.exists.should be_false
      @cutter.error.should be_nil
    end
  end

  describe "with an existing gem" do
    before do
      @cutter = Gem::Cutter.new(@gem_up_file)

      stub(File).exists?(@cache_path) { true }
      stub(File).exists?(@spec_path) { true }
    end

    it "should save gem and update index" do
      stub_spec
      mock_save_and_index
      @cutter.process
      @cutter.spec.should == @spec
      @cutter.exists.should be_true
      @cutter.error.should be_nil
    end
  end

  describe "querying gems" do
    before do
      @rails1 = ["rails", Gem::Version.new("1.2.6"), "ruby"]
      @rails2 = ["rails", Gem::Version.new("2.3.2"), "ruby"]
      @rake   = ["rake", Gem::Version.new("0.3.7"), "ruby"]

      data = "data"
      mock(File).open(Gemcutter.server_path("latest_specs.4.8")) { data }
      mock(Marshal).load(data) { [@rake, @rails1, @rails2] }
    end
    it "should find all unique gems" do
      Gem::Cutter.find_all.should == [@rails2, @rake]
    end

    it "should count gems" do
      Gem::Cutter.count.should == 2
    end
  end
end
