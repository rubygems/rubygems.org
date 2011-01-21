require 'test_helper'

class HostessTest < ActiveSupport::TestCase
  def app
    Hostess.new
  end

  def touch(path, local = true)
    Hostess.local = local
    if local
      path = Pusher.server_path(path)
      FileUtils.mkdir_p(File.dirname(path))
      FileUtils.touch(path)
    end
  end

  setup do
    Hostess.local = false
  end

  %w[/prerelease_specs.4.8.gz
     /latest_specs.4.8.gz
     /specs.4.8.gz
     /Marshal.4.8.Z
     /latest_specs.4.8
     /prerelease_specs.4.8
     /specs.4.8
     /Marshal.4.8
     /quick/index
     /quick/index.rz
     /quick/latest_index
     /quick/latest_index.rz
     /quick/rubygems-update-1.3.6.gemspec.rz
     /yaml
     /yaml.Z
     /yaml.z
  ].each do |index|
    should "serve up #{index} locally" do
      touch index, true
      get index
      assert_equal 200, last_response.status
    end

    should "serve up #{index} remotely" do
      touch index, false
      get index
      assert_equal 302, last_response.status
    end
  end

  context "with gem" do
    setup do
      @download_count = Download.count
      @file = "/gems/test-0.0.0.gem"
      @rubygem = Factory(:rubygem, :name => "test")
      @version = Factory(:version, :rubygem => @rubygem, :number => "0.0.0")
    end

    should "increase download count" do
      get @file

      assert_equal @download_count + 1, Download.count
      assert_equal 1, @rubygem.reload.downloads
      assert_equal 1, @version.reload.downloads_count
    end

    should "redirect to cdn for a gem" do
      get @file

      assert_equal "http://#{$rubygems_config[:cf_domain]}#{@file}", last_response.headers["Location"]
      assert_equal 302, last_response.status
    end
  end

  should "not be able to find bad gem" do
    get "/gems/rails-3.0.0.gem"
    assert_equal 404, last_response.status
  end

  should "find gemspec if loaded in redis" do
    rubygem = Factory(:rubygem, :name => "rails")
    version = Factory(:version, :number => "4.0.0", :rubygem => rubygem)

    path = "/quick/Marshal.4.8/#{version.full_name}.gemspec.rz"
    touch path, false
    get path
    assert_equal 302, last_response.status
  end

  should "not be able to find a bad gemspec" do
    $redis.flushdb
    get "/quick/Marshal.4.8/rails-3.0.0.gemspec.rz"
    assert_equal 404, last_response.status
  end

  should "serve up gem locally" do
    Hostess.local = true
    download_count = Download.count
    file = "/gems/test-0.0.0.gem"
    FileUtils.cp gem_file.path, Pusher.server_path("gems")

    rubygem = Factory(:rubygem, :name => "test")
    version = Factory(:version, :rubygem => rubygem, :number => "0.0.0")

    get file
    assert_equal 200, last_response.status
    assert_equal download_count + 1, Download.count
    assert_equal 1, rubygem.reload.downloads
    assert_equal 1, version.reload.downloads_count
  end

  should "redirect to /gems for /downloads" do
    get "/downloads/rails-3.0.0.gem"
    assert_equal "/gems/rails-3.0.0.gem", last_response.headers["Location"]
    assert_equal 302, last_response.status
  end
end
