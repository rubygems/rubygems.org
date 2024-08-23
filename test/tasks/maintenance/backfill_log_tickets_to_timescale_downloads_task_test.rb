# frozen_string_literal: true

require "test_helper"

module Maintenance
  class BackfillLogTicketsToTimescaleDownloadsTaskTest < ActiveSupport::TestCase
    setup do
      @sample_log = Rails.root.join("test", "sample_logs", "fastly-fake.log").read

      @sample_log_counts = {
        "bundler-1.10.6" => 2,
        "json-1.8.3-java" => 2,
        "json-1.8.3" => 1,
        "json-1.8.2" => 4,
        "no-such-gem-1.2.3" => 1
      }

      @log_download = LogDownload.create!(backend: "s3", directory: "test-bucket", key: "fastly-fake.log", status: "pending")

      Aws.config[:s3] = {
        stub_responses: { get_object: { body: @sample_log } }
      }
      Download.connection.execute("truncate table downloads")
    end

    test "process" do
      Maintenance::BackfillLogTicketsToTimescaleDownloadsTask.process(@log_download)
      refresh_all_caggs!
      @log_download.reload
      assert_equal 10, @log_download.processed_count
      assert_equal "processed", @log_download.status
      assert_equal 10, Download.count
      summary_counts = Download::VersionsPerHour.all.each_with_object({}){|e,summary|summary[e.gem_name+"-"+e.gem_version] = e.downloads}
      assert_equal @sample_log_counts, summary_counts
    end
  end
end
