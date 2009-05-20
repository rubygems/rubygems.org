require File.join(File.dirname(__FILE__), 'spec_helper')

describe Gem::Cutter do
  before do
    @gem = "test-0.0.0.gem"
    @gem_file = gem_file(@gem)
    @cache_path = Gem::Cutter.server_path("cache", @gem)
    @spec_path = Gem::Cutter.server_path("specifications", @gem + "spec")
  end

  describe "with a new gem" do
    before do
      @cutter = Gem::Cutter.new(@gem_file)
    end

    it "should store data" do
      @cutter.data.should == @gem_file
    end

    it "should save gem and update index" do
      @cutter.save_gem
      File.exists?(@cache_path).should be_true
      File.exists?(@spec_path).should be_true
      FileUtils.compare_file(@gem_file.path, @cache_path).should be_true
      File.exists?(Gem::Cutter.server_path("quick", "Marshal.4.8", "#{@gem}spec.rz")).should be_true
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
      File.exists?(Gem::Cutter.server_path("quick", "Marshal.4.8", "#{@gem}spec.rz")).should be_true
    end
  end
end
