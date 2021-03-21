require "test_helper"
require_relative "../../../../lib/gemcutter/middleware/hostess"

class Gemcutter::Middleware::HostessTest < ActiveSupport::TestCase
  include Rack::Test::Methods

  setup do
    create(:gem_download)
  end

  def app
    Gemcutter::Middleware::Hostess.new(-> { [200, {}, ""] })
  end

  def touch(path)
    RubygemFs.instance.store(path, "")
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
     /yaml.z].each do |index|
    should "serve up #{index} locally" do
      touch index
      get index
      assert_equal 200, last_response.status
    end
  end

  context "with gem" do
    setup do
      @download_count = GemDownload.total_count
      @file = "/gems/test-0.0.0.gem"
      @rubygem = create(:rubygem, name: "test")
      @version = create(:version, rubygem: @rubygem, number: "0.0.0")
    end

    should "increase download count" do
      get @file

      assert_equal @download_count + 1, GemDownload.total_count
      assert_equal 1, @rubygem.reload.downloads
      assert_equal 1, @version.reload.downloads_count
    end
  end

  should "not be able to find bad gem" do
    get "/gems/rails-3.0.0.gem"
    assert_equal 404, last_response.status
  end

  should "find gemspec" do
    rubygem = create(:rubygem, name: "rails")
    version = create(:version, number: "4.0.0", rubygem: rubygem)

    path = "/quick/Marshal.4.8/#{version.full_name}.gemspec.rz"
    touch path
    get path
    assert_equal 200, last_response.status
  end

  should "not be able to find a bad gemspec" do
    get "/quick/Marshal.4.8/rails-3.0.0.gemspec.rz"
    assert_equal 404, last_response.status
  end

  should "serve up gem locally" do
    download_count = GemDownload.total_count
    file = "/gems/test-0.0.0.gem"
    touch file
    rubygem = create(:rubygem, name: "test")
    version = create(:version, rubygem: rubygem, number: "0.0.0")

    get file
    assert_equal 200, last_response.status
    assert_equal download_count + 1, GemDownload.total_count
    assert_equal 1, rubygem.reload.downloads
    assert_equal 1, version.reload.downloads_count
  end
end
