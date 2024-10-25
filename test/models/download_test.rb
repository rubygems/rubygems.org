require "test_helper"

class DownloadTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

  # This will run once before all tests in this class
  setup do
    # Truncate the table because we are using a transaction
    Download.connection.execute("truncate table downloads")
  end

  teardown do
    travel_back
    # Truncate the table because we are using a transaction
    Download.connection.execute("truncate table downloads")
  end

  def refresh_all!
    # We need to commit the transaction to make sure the continuous aggregates are refreshed with latest data
    Download.connection.commit_db_transaction
    Download.refresh_aggregates
  end

  context ".rollup(:minute)" do
    should "return downloads per minute" do
      travel_to Time.zone.local(2024, 8, 24, 12, 0, 0) do
        assert_equal 0, Download.count

        create(:download, created_at: 2.minutes.ago)
        create(:download, created_at: 1.minute.ago)
        create(:download, created_at: 1.minute.ago)

        assert_equal [1, 2], Download.total_downloads.rollup(:minute).map(&:downloads)
      end
    end
  end

  context ".downloads_by_gem.rollup(:minute)" do
    should "return gems downloads per minute" do
      travel_to Time.zone.local(2024, 8, 24, 12, 0, 0) do
        assert_equal [], Download.downloads_by_gem.rollup(:minute).map(&:downloads)

        create(:download, gem_name: "example", created_at: 2.minutes.ago)
        create(:download, gem_name: "example", created_at: 1.minute.ago)
        create(:download, gem_name: "example", created_at: 1.minute.ago)
        create(:download, gem_name: "example2", created_at: 1.minute.ago)

        assert_equal [1, 2], Download.downloads_by_gem.rollup(:minute).where(gem_name: "example").map(&:downloads)
        assert_equal [1], Download.downloads_by_gem.rollup(:minute).where(gem_name: "example2").map(&:downloads)
      end
    end
  end

  context ".downloads_by_version.rollup(:minute)" do
    should "return versions downloads per minute" do
      travel_to Time.zone.local(2024, 8, 24, 12, 0, 0) do
        assert_equal 0, Download.count

        create(:download, gem_name: "example", gem_version: "0.0.1", created_at: 2.minutes.ago)
        create(:download, gem_name: "example", gem_version: "0.0.1", created_at: 1.minute.ago)
        create(:download, gem_name: "example", gem_version: "0.0.2", created_at: 1.minute.ago)
        create(:download, gem_name: "example", gem_version: "0.0.2", created_at: 1.minute.ago)
        create(:download, gem_name: "example2", gem_version: "0.0.1", created_at: 1.minute.ago)

        assert_equal [1, 1], Download.downloads_by_version.rollup(:minute).where(gem_name: "example", gem_version: "0.0.1").map(&:downloads)
        assert_equal [2], Download.downloads_by_version.rollup(:minute).where(gem_name: "example", gem_version: "0.0.2").map(&:downloads)
        assert_equal [1], Download.downloads_by_version.rollup(:minute).where(gem_name: "example2", gem_version: "0.0.1").map(&:downloads)
      end
    end
  end

  context "Continuous Aggregate" do
    should "materialized views by minute, hour, day and month" do
      assert Download::TotalDownloadsPerMinute.table_exists?
      assert Download::TotalDownloadsPerHour.table_exists?
      assert Download::TotalDownloadsPerDay.table_exists?
      assert Download::TotalDownloadsPerMonth.table_exists?

      assert Download::DownloadsByGemPerMinute.table_exists?
      assert Download::DownloadsByGemPerHour.table_exists?
      assert Download::DownloadsByGemPerDay.table_exists?
      assert Download::DownloadsByGemPerMonth.table_exists?

      assert Download::DownloadsByVersionPerMinute.table_exists?
      assert Download::DownloadsByVersionPerHour.table_exists?
      assert Download::DownloadsByVersionPerDay.table_exists?
      assert Download::DownloadsByVersionPerMonth.table_exists?

    end

    should "refresh materialized views" do
      travel_to Time.zone.local(2024, 8, 24, 12, 0, 0) do
        [1.year.ago, 11.months.ago, 10.months.ago, 3.months.ago, 1.month.ago, 1.day.ago, 1.hour.ago, 1.minute.ago, 30.seconds.ago].each do |created_at|
          create(:download, gem_name: "alpha", gem_version: "0.0.1", created_at: created_at)
        end

        [3.months.ago, 1.month.ago, 1.day.ago, 1.hour.ago, 1.minute.ago, 45.seconds.ago].each do |created_at|
          create(:download, gem_name: "beta", gem_version: "0.0.1", created_at: created_at)
        end

        refresh_all!

        assert_equal 15, Download.count
        assert_equal 8, Download::TotalDownloadsPerMinute.count
        assert_equal 7, Download::TotalDownloadsPerHour.count
        assert_equal 7, Download::TotalDownloadsPerDay.count
        assert_equal 6, Download::TotalDownloadsPerMonth.count

        expected_per_minute = [
          {"created_at":"2023-08-24T12:00:00.000Z","downloads":1},
          {"created_at":"2023-09-24T12:00:00.000Z","downloads":1},
          {"created_at":"2023-10-24T12:00:00.000Z","downloads":1},  
          {"created_at":"2024-05-24T12:00:00.000Z","downloads":2},
          {"created_at":"2024-07-24T12:00:00.000Z","downloads":2},
          {"created_at":"2024-08-23T12:00:00.000Z","downloads":2},
          {"created_at":"2024-08-24T11:00:00.000Z","downloads":2},
          {"created_at":"2024-08-24T11:59:00.000Z","downloads":4}
        ].map{|h| h[:created_at] = Time.zone.parse(h[:created_at]); h}

        assert_equal expected_per_minute, Download::TotalDownloadsPerMinute.order(:created_at).all.map{_1.attributes.symbolize_keys}

        expected_per_hour = [
          {"created_at":"2023-08-24T12:00:00.000Z","downloads":1},
          {"created_at":"2023-09-24T12:00:00.000Z","downloads":1},
          {"created_at":"2023-10-24T12:00:00.000Z","downloads":1},
          {"created_at":"2024-05-24T12:00:00.000Z","downloads":2},
          {"created_at":"2024-07-24T12:00:00.000Z","downloads":2},
          {"created_at":"2024-08-23T12:00:00.000Z","downloads":2},
          {"created_at":"2024-08-24T11:00:00.000Z","downloads":6},
        ].map{|h| h[:created_at] = Time.zone.parse(h[:created_at]); h}

        assert_equal expected_per_hour, Download::TotalDownloadsPerHour.order(created_at: :asc).all.map{_1.attributes.symbolize_keys}

        expected_per_day = [
          {"created_at":"2023-08-24T00:00:00.000Z","downloads":1},
          {"created_at":"2023-09-24T00:00:00.000Z","downloads":1},
          {"created_at":"2023-10-24T00:00:00.000Z","downloads":1},
          {"created_at":"2024-05-24T00:00:00.000Z","downloads":2},
          {"created_at":"2024-07-24T00:00:00.000Z","downloads":2},
          {"created_at":"2024-08-23T00:00:00.000Z","downloads":2},
          {"created_at":"2024-08-24T00:00:00.000Z","downloads":6},
        ].map{|h| h[:created_at] = Time.zone.parse(h[:created_at]); h}

        assert_equal expected_per_day, Download::TotalDownloadsPerDay.order(:created_at).all.map{_1.attributes.symbolize_keys}

        expected_per_month = [
          {"created_at":"2023-08-01T00:00:00.000Z","downloads":1},
          {"created_at":"2023-09-01T00:00:00.000Z","downloads":1},
          {"created_at":"2023-10-01T00:00:00.000Z","downloads":1},
          {"created_at":"2024-05-01T00:00:00.000Z","downloads":2},
          {"created_at":"2024-07-01T00:00:00.000Z","downloads":2},
          {"created_at":"2024-08-01T00:00:00.000Z","downloads":8},
        ].map{|h| h[:created_at] = Time.zone.parse(h[:created_at]); h}

        assert_equal expected_per_month, Download::TotalDownloadsPerMonth.order(:created_at).all.map{_1.attributes.symbolize_keys}

        assert_equal [1, 1, 1, 2, 2, 2, 2, 4], Download::TotalDownloadsPerMinute.order(:created_at).all.map{_1.attributes["downloads"]}

        downloads_per_minute = -> (gem_name) { Download::DownloadsByGemPerMinute.where('gem_name': gem_name).order(:created_at).pluck('downloads')}
        assert_equal [1, 1, 1, 1, 1, 1, 1, 2], downloads_per_minute.("alpha")
        assert_equal [1,1,1,1,2], downloads_per_minute.("beta")

        downloads_per_hour = -> (gem_name) { Download::DownloadsByGemPerHour.where('gem_name': gem_name).order(:created_at).pluck('downloads')}
        assert_equal [1, 1, 1, 1, 1, 1, 3], downloads_per_hour.("alpha")
        assert_equal [1, 1, 1, 3], downloads_per_hour.("beta")

        downloads_per_day = -> (gem_name) { Download::DownloadsByGemPerDay.where('gem_name': gem_name).order(:created_at).pluck('downloads')}
        assert_equal [1, 1, 1, 1, 1, 1, 3], downloads_per_day.("alpha")
        assert_equal [1, 1, 1, 3], downloads_per_day.("beta")

        downloads_per_month = -> (gem_name) { Download::DownloadsByGemPerMonth.where('gem_name': gem_name).order(:created_at).pluck('downloads')}
        assert_equal [1, 1, 1, 1, 1, 4], downloads_per_month.("alpha")
        assert_equal [1, 1, 4], downloads_per_month.("beta")
      end
    end
  end
end