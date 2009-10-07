require File.dirname(__FILE__) + '/../test_helper'

class DownloadTest < ActiveSupport::TestCase
  should "be valid with factory" do
    assert_valid Factory.build(:download)
  end
  should_belong_to :version
  should_have_db_index :version_id

  should "load up all downloads with just raw strings and process them" do
    rubygem = Factory(:rubygem)
    version = Factory(:version, :rubygem => rubygem)

    raw_download = Download.new(:raw => "#{rubygem.name}-#{version.number}")
    raw_download.perform

    assert_equal raw_download.reload.version, version
    assert_equal 1, version.reload.downloads_count
  end
end
