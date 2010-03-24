require File.dirname(__FILE__) + '/../test_helper'

class DownloadTest < ActiveSupport::TestCase
  should "load up all downloads with just raw strings and process them" do
    rubygem = Factory(:rubygem, :name => "some-stupid13-gem42-9000")
    version = Factory(:version, :rubygem => rubygem)

    3.times do
      Download.incr(version)
    end

    assert_equal 3, version.downloads_count
    assert_equal 3, rubygem.downloads
    assert_equal 3, Download.count
    assert_equal 3, Download.today(version)
  end

  should "track platform gem downloads correctly" do
    rubygem = Factory(:rubygem)
    version = Factory(:version, :rubygem => rubygem, :platform => "mswin32-60")
    other_platform_version = Factory(:version, :rubygem => rubygem, :platform => "mswin32")

    Download.incr(version)

    assert_equal 1, version.downloads_count
    assert_equal 1, rubygem.downloads
    assert_equal 0, other_platform_version.downloads_count

    assert_equal 1, Download.count
    assert_equal 1, Download.today(version)
    assert_equal 0, Download.today(other_platform_version)
  end
end
