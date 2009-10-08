require File.dirname(__FILE__) + '/../test_helper'

class DownloadTest < ActiveSupport::TestCase
  should "be valid with factory" do
    assert_valid Factory.build(:download)
  end
  should_belong_to :version
  should_have_db_index :version_id

  should "load up all downloads with just raw strings and process them" do
    rubygem = Factory(:rubygem, :name => "some-stupid13-gem42-name9000")
    version = Factory(:version, :rubygem => rubygem)

    3.times do
      raw_download = Download.new(:raw => "#{rubygem.name}-#{version.number}")
      raw_download.perform
      assert_equal raw_download.reload.version, version
    end

    assert_equal 3, version.reload.downloads_count
    assert_equal 3, rubygem.reload.downloads
  end

  should "track platform gem downloads correctly" do
    rubygem = Factory(:rubygem)
    version = Factory(:version, :rubygem => rubygem, :platform => "mswin32-60")
    other_platform_version = Factory(:version, :rubygem => rubygem, :platform => "mswin32")

    raw_download = Download.new(:raw => "#{rubygem.name}-#{version.number}-mswin32-60")
    raw_download.perform

    assert_equal raw_download.reload.version, version
    assert_equal 1, version.reload.downloads_count
    assert_equal 1, rubygem.reload.downloads
    assert_equal 0, other_platform_version.reload.downloads_count
  end
end
