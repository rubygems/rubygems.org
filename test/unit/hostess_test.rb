require 'test_helper'

class HostessTest < ActiveSupport::TestCase
  def app
    Hostess.new
  end

  def touch(path, local = true)
    Hostess.local = local
    if local
      path = Gemcutter.server_path(path)
      FileUtils.mkdir_p(File.dirname(path))
      FileUtils.touch(path)
    else
      net_resp = FakeWeb::Responder.new(:get, "/", {}, 1).response
      s3_resp = AWS::S3::S3Object::Response.new(net_resp)
      stub(VaultObject).value(path, anything) { s3_resp }
    end
  end

  def self.serve_up(index, local)
    should "serve up #{index} #{local ? 'locally' : 'remotely'}" do
      touch index, local
      get index
      assert_equal 200, last_response.status
    end
  end

  setup do
    Hostess.local = false
  end

  %w[/prerelease_specs.4.8.gz
     /latest_specs.4.8.gz
     /specs.4.8.gz
     /Marshal.4.8.Z
     /yaml
     /Marshal.4.8
     /specs.4.8
     /latest_specs.4.8
     /prerelease_specs.4.8
     /quick/Marshal.4.8/test-0.0.0.gemspec.rz
  ].each do |index|
    serve_up index, false
    serve_up index, true
  end

  should "serve up gem remotely" do
    download_count = Download.count
    file = "/gems/test-0.0.0.gem"
    rubygem = Factory(:rubygem, :name => "test")
    version = Factory(:version, :rubygem => rubygem, :number => "0.0.0")

    get file
    Delayed::Job.work_off

    assert_equal 302, last_response.status
    assert_equal download_count + 1, Download.count
    assert_equal 1, rubygem.reload.downloads
    assert_equal 1, version.reload.downloads_count
  end

  should "serve up gem locally" do
    Hostess.local = false
    download_count = Download.count
    file = "/gems/test-0.0.0.gem"
    FileUtils.cp gem_file.path, Gemcutter.server_path("gems")
    
    rubygem = Factory(:rubygem, :name => "test")
    version = Factory(:version, :rubygem => rubygem, :number => "0.0.0")

    get file
    Delayed::Job.work_off

    assert_equal 302, last_response.status
    assert_equal download_count + 1, Download.count
    assert_equal 1, rubygem.reload.downloads
    assert_equal 1, version.reload.downloads_count
  end

  should "not be able to find non existant gemspec" do
    file = "/quick/Marshal.4.8/test-0.0.0.gemspec.rz"
    stub(VaultObject).value(anything, anything) do
      raise AWS::S3::NoSuchKey.new("No such key!", VaultObject.current_bucket)
    end

    get file
    assert_equal 404, last_response.status
  end
end
