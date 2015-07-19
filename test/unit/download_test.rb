require 'test_helper'

class DownloadTest < ActiveSupport::TestCase
  should "load up all downloads with just raw strings and process them" do
    rubygem = create(:rubygem, name: "some-stupid13-gem42-9000")
    version = create(:version, rubygem: rubygem)

    3.times do
      Download.incr(rubygem.name, version.full_name)
    end

    assert_equal 3, version.downloads_count
    assert_equal 3, rubygem.downloads
    assert_equal 3, Download.count
    assert_equal 3, Download.today(version)
  end

  should "track platform gem downloads correctly" do
    rubygem = create(:rubygem)
    version = create(:version, rubygem: rubygem, platform: "mswin32-60")
    other_platform_version = create(:version, rubygem: rubygem, platform: "mswin32")

    Download.incr(rubygem.name, version.full_name)

    assert_equal 1, version.downloads_count
    assert_equal 1, rubygem.downloads
    assert_equal 0, other_platform_version.downloads_count

    assert_equal 1, Download.count
    assert_equal 1, Download.today(version)
    assert_equal 0, Download.today(other_platform_version)
  end

  should "find most downloaded today" do
    @rubygem_1 = create(:rubygem)
    @version_1 = create(:version, rubygem: @rubygem_1)
    @version_2 = create(:version, rubygem: @rubygem_1)

    @rubygem_2 = create(:rubygem)
    @version_3 = create(:version, rubygem: @rubygem_2)

    @rubygem_3 = create(:rubygem)
    @version_4 = create(:version, rubygem: @rubygem_3)

    Timecop.freeze(1.day.ago) do
      Download.incr(@rubygem_1.name, @version_1.full_name)
      Download.incr(@rubygem_1.name, @version_2.full_name)
      Download.incr(@rubygem_2.name, @version_3.full_name)
    end

    Download.incr(@rubygem_1.name, @version_1.full_name)
    3.times { Download.incr(@rubygem_2.name, @version_3.full_name) }
    2.times { Download.incr(@rubygem_1.name, @version_2.full_name) }

    assert_equal [[@version_3, 3], [@version_2, 2], [@version_1, 1]],
      Download.most_downloaded_today

    assert_equal [[@version_3, 3], [@version_2, 2]],
      Download.most_downloaded_today(2)

    assert_equal 3, Download.cardinality
    assert_equal 1, Download.rank(@version_3)
    assert_equal 2, Download.rank(@version_2)
    assert_equal 3, Download.rank(@version_1)

    assert_equal 3, Download.today([@version_1, @version_2])
  end

  should "find most downloaded all time" do
    @rubygem_1 = create(:rubygem)
    @version_1 = create(:version, rubygem: @rubygem_1)
    @version_2 = create(:version, rubygem: @rubygem_1)

    @rubygem_2 = create(:rubygem)
    @version_3 = create(:version, rubygem: @rubygem_2)

    @rubygem_3 = create(:rubygem)
    @version_4 = create(:version, rubygem: @rubygem_3)

    Download.incr(@rubygem_1.name, @version_1.full_name)
    Download.incr(@rubygem_1.name, @version_2.full_name)
    Download.incr(@rubygem_2.name, @version_3.full_name)
    Download.incr(@rubygem_1.name, @version_1.full_name)
    3.times { Download.incr(@rubygem_2.name, @version_3.full_name) }
    2.times { Download.incr(@rubygem_1.name, @version_2.full_name) }

    assert_equal [[@version_3, 4], [@version_2, 3], [@version_1, 2]],
      Download.most_downloaded_all_time

    assert_equal [[@version_3, 4], [@version_2, 3]],
      Download.most_downloaded_all_time(2)

    assert_equal 3, Download.cardinality
    assert_equal 1, Download.rank(@version_3)
    assert_equal 2, Download.rank(@version_2)
    assert_equal 3, Download.rank(@version_1)
  end

  should "find counts per day for versions" do
    @rubygem_1 = create(:rubygem)
    @version_1 = create(:version, rubygem: @rubygem_1)
    @version_2 = create(:version, rubygem: @rubygem_1)

    @rubygem_2 = create(:rubygem)
    @version_3 = create(:version, rubygem: @rubygem_2)

    @rubygem_3 = create(:rubygem)
    @version_4 = create(:version, rubygem: @rubygem_3)

    Timecop.freeze(1.day.ago) do
      Download.incr(@rubygem_1, @version_1.full_name)
      Download.incr(@rubygem_1, @version_2.full_name)
      Download.incr(@rubygem_2, @version_3.full_name)
    end

    Download.incr(@rubygem_2, @version_3.full_name)
    Download.incr(@rubygem_1, @version_1.full_name)
    Download.incr(@rubygem_2, @version_3.full_name)
    Download.incr(@rubygem_2, @version_3.full_name)
    Download.incr(@rubygem_1, @version_2.full_name)

    downloads = {
      "#{@version_1.id}-#{2.days.ago.to_date}" => 0,
      "#{@version_1.id}-#{Time.zone.yesterday}" => 1,
      "#{@version_1.id}-#{Time.zone.today}" => 1,
      "#{@version_2.id}-#{2.days.ago.to_date}" => 0,
      "#{@version_2.id}-#{Time.zone.yesterday}" => 1,
      "#{@version_2.id}-#{Time.zone.today}" => 1,
      "#{@version_3.id}-#{2.days.ago.to_date}" => 0,
      "#{@version_3.id}-#{Time.zone.yesterday}" => 1,
      "#{@version_3.id}-#{Time.zone.today}" => 3
    }

    assert_equal downloads.size, 9
    assert_equal downloads,
      Download.counts_by_day_for_versions([@version_1,
                                           @version_2,
                                           @version_3], 2)
  end

  should "find counts per day for versions when in DB also" do
    @rubygem_1 = create(:rubygem)
    @version_1 = create(:version, rubygem: @rubygem_1)
    @version_2 = create(:version, rubygem: @rubygem_1)

    @rubygem_2 = create(:rubygem)
    @version_3 = create(:version, rubygem: @rubygem_2)

    @rubygem_3 = create(:rubygem)
    @version_4 = create(:version, rubygem: @rubygem_3)

    Timecop.freeze(1.day.ago) do
      create :version_history, version: @version_1, count: 5
      create :version_history, version: @version_2
      create :version_history, version: @version_3
    end

    Download.incr(@rubygem_2, @version_3.full_name)
    Download.incr(@rubygem_1, @version_1.full_name)
    Download.incr(@rubygem_2, @version_3.full_name)
    Download.incr(@rubygem_2, @version_3.full_name)
    Download.incr(@rubygem_1, @version_2.full_name)

    downloads = {
      "#{@version_1.id}-#{2.days.ago.to_date}" => 0,
      "#{@version_1.id}-#{Time.zone.yesterday}" => 5,
      "#{@version_1.id}-#{Time.zone.today}" => 1,
      "#{@version_2.id}-#{2.days.ago.to_date}" => 0,
      "#{@version_2.id}-#{Time.zone.yesterday}" => 1,
      "#{@version_2.id}-#{Time.zone.today}" => 1,
      "#{@version_3.id}-#{2.days.ago.to_date}" => 0,
      "#{@version_3.id}-#{Time.zone.yesterday}" => 1,
      "#{@version_3.id}-#{Time.zone.today}" => 3
    }

    assert_equal downloads.size, 9
    assert_equal downloads,
      Download.counts_by_day_for_versions([@version_1,
                                           @version_2,
                                           @version_3], 2)
  end

  should "find counts per day for versions in range across month boundary" do
    Timecop.freeze(Time.zone.parse("2012-10-01")) do
      @rubygem_1 = create(:rubygem)
      @version_1 = create(:version, rubygem: @rubygem_1)

      Timecop.freeze(1.day.ago) do
        create :version_history, version: @version_1, count: 5
      end

      Download.incr(@rubygem_1, @version_1.full_name)

      start = 2.days.ago.to_date
      fin = Time.zone.today

      downloads = ActiveSupport::OrderedHash.new.tap do |d|
        d[start.to_s] = 0
        d["#{Time.zone.yesterday}"] = 5
        d[fin.to_s] = 1
      end

      assert_equal downloads,
        Download.counts_by_day_for_version_in_date_range(@version_1, start, fin)
    end
  end

  should "find counts per day for versions in range" do
    @rubygem_1 = create(:rubygem)
    @version_1 = create(:version, rubygem: @rubygem_1)

    Timecop.freeze(1.day.ago) do
      create :version_history, version: @version_1, count: 5
    end

    Download.incr(@rubygem_1, @version_1.full_name)

    start = 2.days.ago.to_date
    fin = Time.zone.today

    downloads = ActiveSupport::OrderedHash.new.tap do |d|
      d[start.to_s] = 0
      d["#{Time.zone.yesterday}"] = 5
      d[fin.to_s] = 1
    end

    assert_equal downloads, Download.counts_by_day_for_version_in_date_range(@version_1, start, fin)
  end

  should "find download count by gem name" do
    rubygem = create(:rubygem)
    version1 = create(:version, rubygem: rubygem)
    version2 = create(:version, rubygem: rubygem)

    3.times { Download.incr(rubygem.name, version1.full_name) }
    2.times { Download.incr(rubygem.name, version2.full_name) }

    assert_equal 5, Download.for_rubygem(rubygem.name)
    assert_equal 3, Download.for_version(version1.full_name)
    assert_equal 2, Download.for_version(version2.full_name)
  end

  should "return zero for rank if no downloads exist" do
    assert_equal 0, Download.rank(build(:version))
  end

  should "delete all old today keys except the current" do
    rubygem = create(:rubygem)
    version = create(:version, rubygem: rubygem)
    10.times do |n|
      Timecop.freeze(n.days.ago) do
        3.times { Download.incr(rubygem.name, version.full_name) }
      end
    end
    assert_equal 9, Download.today_keys.size
    Download.cleanup_today_keys
    assert_equal 0, Download.today_keys.size
  end

  should "copy data from redis into SQL" do
    rubygem = create(:rubygem)
    version = create(:version, rubygem: rubygem)

    Download.incr rubygem.name, version.full_name

    date = Time.zone.today.to_s

    assert_equal nil, VersionHistory.for(version, date)

    Download.copy_to_sql version, date

    assert_equal 1, VersionHistory.for(version, date).count

    Download.incr rubygem.name, version.full_name

    Download.copy_to_sql version, date

    assert_equal 2, VersionHistory.for(version, date).count
  end

  should "copy all be the last 2 days into SQL" do
    rubygem = create(:rubygem)
    version = create(:version, rubygem: rubygem)

    10.times do |n|
      Timecop.freeze(n.days.ago) do
        3.times { Download.incr(rubygem.name, version.full_name) }
      end
    end

    Download.migrate_to_sql version

    assert_equal [1.day.ago.to_date.to_s, Time.zone.today.to_s].sort,
      Redis.current.hkeys(Download.history_key(version)).sort
  end

  should "migrate all keys in redis" do
    rubygem = create(:rubygem)
    version = create(:version, rubygem: rubygem)

    10.times do |n|
      Timecop.freeze(n.days.ago) do
        3.times { Download.incr(rubygem.name, version.full_name) }
      end
    end

    assert_equal 1, Download.migrate_all_to_sql

    assert_equal [1.day.ago.to_date.to_s, Time.zone.today.to_s].sort,
      Redis.current.hkeys(Download.history_key(version)).sort
  end

  context "with redis down" do
    should "return nil for count" do
      requires_toxiproxy
      Toxiproxy[:redis].down do
        assert_equal nil, Download.count
      end
    end
  end
end
