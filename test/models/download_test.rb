require "test_helper"

class DownloadTest < ActiveSupport::TestCase
  # This will run once before all tests in this class
  setup do
    # Truncate the table because we are using a transaction
    Download.connection.execute("truncate table downloads")
  end

  teardown do
    # Truncate the table because we are using a transaction
    Download.connection.execute("truncate table downloads")
  end

  def refresh_all!
    # We need to commit the transaction to make sure the continuous aggregates are refreshed with latest data
    Download.connection.commit_db_transaction
    Download::MaterializedViews.each do |view|
      view.refresh!
    end
  end

  context ".per_minute" do
    should "return downloads per minute" do

      assert_equal [], Download.per_minute

      create(:download, created_at: 2.minutes.ago)
      create(:download, created_at: 1.minute.ago)
      create(:download, created_at: 1.minute.ago)

      assert_equal [1, 2], Download.per_minute.map(&:downloads)
    end
  end

  context ".gems_per_minute" do
    should "return gems downloads per minute" do
      create(:download, gem_name: "example", created_at: 2.minutes.ago)
      create(:download, gem_name: "example", created_at: 1.minute.ago)
      create(:download, gem_name: "example", created_at: 1.minute.ago)
      create(:download, gem_name: "example2", created_at: 1.minute.ago)

      assert_equal [1, 2], Download.gems_per_minute.where(gem_name: "example").map(&:downloads)
      assert_equal [1], Download.gems_per_minute.where(gem_name: "example2").map(&:downloads)
    end
  end

  context ".versions_per_minute" do
    should "return versions downloads per minute" do
      create(:download, gem_name: "example", gem_version: "0.0.1", created_at: 2.minutes.ago)
      create(:download, gem_name: "example", gem_version: "0.0.1", created_at: 1.minute.ago)
      create(:download, gem_name: "example", gem_version: "0.0.2", created_at: 1.minute.ago)
      create(:download, gem_name: "example", gem_version: "0.0.2", created_at: 1.minute.ago)
      create(:download, gem_name: "example2", gem_version: "0.0.1", created_at: 1.minute.ago)

      assert_equal [1, 1], Download.versions_per_minute.where(gem_name: "example", gem_version: "0.0.1").map(&:downloads)
      assert_equal [2], Download.versions_per_minute.where(gem_name: "example", gem_version: "0.0.2").map(&:downloads)
      assert_equal [1], Download.versions_per_minute.where(gem_name: "example2", gem_version: "0.0.1").map(&:downloads)
    end
  end

  context "Continuous Aggregate" do
    should "materialized views by minute, hour, day and month" do
      assert Download::PerMinute.table_exists?
      assert Download::PerHour.table_exists?
      assert Download::PerDay.table_exists?
      assert Download::PerMonth.table_exists?

      assert Download::GemsPerMinute.table_exists?
      assert Download::GemsPerHour.table_exists?
      assert Download::GemsPerDay.table_exists?
      assert Download::GemsPerMonth.table_exists?

      assert Download::VersionsPerMinute.table_exists?
      assert Download::VersionsPerHour.table_exists?
      assert Download::VersionsPerDay.table_exists?
      assert Download::VersionsPerMonth.table_exists?

      assert Download::MaterializedViews == [
        Download::PerMinute,
        Download::PerHour,
        Download::PerDay,
        Download::PerMonth,
        Download::GemsPerMinute,
        Download::GemsPerHour,
        Download::GemsPerDay,
        Download::GemsPerMonth,
        Download::VersionsPerMinute,
        Download::VersionsPerHour,
        Download::VersionsPerDay,
        Download::VersionsPerMonth
      ]
    end

    should "refresh materialized views" do

      create(:download, created_at: 2.minutes.ago)
      create(:download, created_at: 1.minute.ago)
      create(:download, gem_name: "example", created_at: 1.minute.ago)
      create(:download, gem_name: "example", gem_version: "0.0.1", created_at: 1.minute.ago)
      create(:download, gem_name: "example", gem_version: "0.0.2", created_at: 1.minute.ago)
      create(:download, gem_name: "example2", gem_version: "0.0.1", created_at: 1.minute.ago)
      create(:download, gem_name: "example2", gem_version: "0.0.2", created_at: 1.minute.ago)

      assert Download.count == 7

      refresh_all!

      assert Download::PerMinute.count == 2
      assert Download::PerMinute.all.map{_1.attributes["downloads"]} == [1, 6]

      previous = Download::PerMinute
      %w[PerHour PerDay PerMonth].each do |view|
        cagg = "Download::#{view}".constantize
        scope = previous.send(view.underscore)
        assert cagg.count == 1, "Expected Download::#{view}.count to be 1, got #{cagg.count}"
        assert cagg.all.map(&:attributes) == scope.map(&:attributes)
        previous = cagg
      end

      downloads_per_minute = -> (gem_name) { Download::GemsPerMinute.where('gem_name': gem_name).pluck('downloads')}
      assert downloads_per_minute.("example") == [1, 4]
      assert downloads_per_minute.("example2") == [2]

      downloads_per_hour = -> (gem_name) { Download::GemsPerHour.where('gem_name': gem_name).pluck('downloads')}
      assert downloads_per_hour.("example") == [5]
      assert downloads_per_hour.("example2") == [2]

      downloads_per_day = -> (gem_name) { Download::GemsPerDay.where('gem_name': gem_name).pluck('downloads')}
      assert downloads_per_day.("example") == [5]
      assert downloads_per_day.("example2") == [2]

      downloads_per_month = -> (gem_name) { Download::GemsPerMonth.where('gem_name': gem_name).pluck('downloads')}
      assert downloads_per_month.("example") == [5]
      assert downloads_per_month.("example2") == [2]
    end
  end
end