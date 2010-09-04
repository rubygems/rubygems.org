require 'test_helper'

class DownloadTest < ActiveSupport::TestCase
  should "load up all downloads with just raw strings and process them" do
    rubygem = Factory(:rubygem, :name => "some-stupid13-gem42-9000")
    version = Factory(:version, :rubygem => rubygem)

    3.times do
      Download.incr(rubygem.name, version.full_name)
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

    Download.incr(rubygem.name, version.full_name)

    assert_equal 1, version.downloads_count
    assert_equal 1, rubygem.downloads
    assert_equal 0, other_platform_version.downloads_count

    assert_equal 1, Download.count
    assert_equal 1, Download.today(version)
    assert_equal 0, Download.today(other_platform_version)
  end

  context "with some gems downloaded" do
    setup do
      @rubygem = Factory(:rubygem)
      @version1 = Factory(:version, :rubygem => @rubygem, :number => "1.0.0")
      @version2 = Factory(:version, :rubygem => @rubygem, :number => "2.0.0")

      Download.incr(@rubygem.name, @version1.full_name)
      Download.incr(@rubygem.name, @version2.full_name)
      Download.incr(@rubygem.name, @version2.full_name)
    end

    should "roll over downloads into history hashes" do
      Download.rollover
      assert ! $redis.exists(Download::TODAY_KEY)
      assert $redis.exists(Download::YESTERDAY_KEY)

      rubygem_history = $redis.hgetall(Download.history_key(@rubygem))
      version1_history = $redis.hgetall(Download.history_key(@version1))
      version2_history = $redis.hgetall(Download.history_key(@version2))

      yesterday = 1.day.ago.to_date.to_s
      assert_equal 3, rubygem_history[yesterday].to_i
      assert_equal 1, version1_history[yesterday].to_i
      assert_equal 2, version2_history[yesterday].to_i
    end

    should "update the database when we roll over" do
      Download.rollover

      assert_equal 3, @rubygem.reload.read_attribute(:downloads)
    end
  end

  should "find most downloaded today" do
    @rubygem_1 = Factory(:rubygem)
    @version_1 = Factory(:version, :rubygem => @rubygem_1)
    @version_2 = Factory(:version, :rubygem => @rubygem_1)

    @rubygem_2 = Factory(:rubygem)
    @version_3 = Factory(:version, :rubygem => @rubygem_2)

    @rubygem_3 = Factory(:rubygem)
    @version_4 = Factory(:version, :rubygem => @rubygem_3)

    Download.incr(@rubygem_1.name, @version_1.full_name)
    Download.incr(@rubygem_1.name, @version_2.full_name)
    Download.incr(@rubygem_2.name, @version_3.full_name)
    Download.rollover
    Download.incr(@rubygem_2.name, @version_3.full_name)
    Download.incr(@rubygem_1.name, @version_1.full_name)
    Download.incr(@rubygem_2.name, @version_3.full_name)
    Download.incr(@rubygem_2.name, @version_3.full_name)
    Download.incr(@rubygem_1.name, @version_2.full_name)

    assert_equal [[@version_3, 3], [@version_2, 1], [@version_1, 1]],
                 Download.most_downloaded_today
  end
end
