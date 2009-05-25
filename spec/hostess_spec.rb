require File.join(File.dirname(__FILE__), 'spec_helper')
require 'apps/hostess/hostess'

describe Gem::Hostess do
  def app
    Gem::Hostess.new
  end

  def touch(path)
    path = Gemcutter.server_path(path)
    FileUtils.touch(path)
  end

  def remove(path)
    path = Gemcutter.server_path(path)
    FileUtils.rm(path) if File.exists?(path)
  end

  it "should have a homepage" do
    get "/"
    last_response.status.should == 200
    last_response.body.should =~ /gemcutter/
  end

  it "should return latest specs" do
    file = "/latest_specs.4.8.gz"
    touch file
    get file
    last_response.status.should == 200
  end

  it "should return quick gemspec" do
    file = "/quick/Marshal.4.8/test-0.0.0.gemspec.rz"
    touch file
    get file
    last_response.status.should == 200
    last_response.content_type.should == "application/x-deflate"
  end

  it "should return gem" do
    file = "/gems/test-0.0.0.gem"
    touch file
    get file
    last_response.status.should == 200
  end

  it "should not be able to find non existant gemspec" do
    file = "/quick/Marshal.4.8/test-0.0.0.gemspec.rz"
    remove file
    get file
    last_response.status.should == 404
  end

  it "should not be able to find non existant gem" do
    file = "/gems/test-0.0.0.gem"
    remove file
    get file
    last_response.status.should == 404
  end
end
