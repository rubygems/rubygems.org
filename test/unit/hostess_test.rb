require 'test_helper'

class HostessTest < ActiveSupport::TestCase
  def app
    Hostess.new
  end

  def touch(path)
    path = Gemcutter.server_path(path)
    FileUtils.mkdir_p(File.dirname(path))
    FileUtils.touch(path)
  end

  def remove(path)
    path = Gemcutter.server_path(path)
    FileUtils.rm(path) if File.exists?(path)
  end

  ["/prerelease_specs.4.8.gz",
   "/latest_specs.4.8.gz",
   "/specs.4.8.gz",
   "/Marshal.4.8.Z"].each do |index|
    should "serve up #{index}" do
      touch index
      get index
      assert_not_nil last_response.headers["Cache-Control"]
      assert_equal 200, last_response.status
    end
  end

  ["/yaml",
   "/Marshal.4.8",
   "/specs.4.8",
   "/latest_specs.4.8"].each do |old_index|
    should "not serve up #{old_index}" do
      get old_index
      assert_equal 403, last_response.status
      assert_match /gem update --system/, last_response.body
    end
  end

  should "return quick gemspec" do
    file = "/quick/Marshal.4.8/test-0.0.0.gemspec.rz"
    touch file
    get file
    assert_not_nil last_response.headers["Cache-Control"]
    assert_equal 200, last_response.status
    assert_equal "application/x-deflate", last_response.content_type
  end

  should "serve up gem" do
    download_count = Download.count
    file = "/gems/test-0.0.0.gem"
    FileUtils.cp gem_file.path, Gemcutter.server_path("gems")
    rubygem = Factory(:rubygem, :name => "test")
    version = Factory(:version, :rubygem => rubygem, :number => "0.0.0")

    get file
    Delayed::Job.work_off

    assert_equal 200, last_response.status
    assert_equal download_count + 1, Download.count
    assert_equal 1, rubygem.reload.downloads
    assert_equal 1, version.reload.downloads_count
  end

  should "not be able to find non existant gemspec" do
    file = "/quick/Marshal.4.8/test-0.0.0.gemspec.rz"
    remove file
    get file
    assert_equal 404, last_response.status
  end

  should "not be able to find non existant gem" do
    file = "/gems/test-0.0.0.gem"
    remove file
    get file
    assert_equal 404, last_response.status
  end
end
