require "test_helper"

class FastlyLogDownloadsProcessorJobTest < ActiveJob::TestCase
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
    @processor = FastlyLogDownloadsProcessor.new("test-bucket", "fastly-fake.log")
    @job = FastlyLogDownloadsProcessorJob.new(bucket: "test-bucket", key: "fastly-fake.log")
    Download.connection.execute("truncate table downloads")
  end

  teardown do
    # Remove stubbed response
    Aws.config.delete(:s3)
  end

  def perform_and_refresh
    count = @processor.perform
    refresh_all_caggs!
    count
  end

  context "#perform" do
    should "process file" do
      assert_equal 10, perform_and_refresh
      summary_counts = Download::VersionsPerHour.all.each_with_object({}){|e,summary|summary[e.gem_name+"-"+e.gem_version] = e.downloads}
      assert_equal @sample_log_counts, summary_counts
    end

    should "fail if dont find the file" do
      @log_download.update(backend: "local", directory: "foobar")
      assert_raises FastlyLogDownloadsProcessor::LogFileNotFoundError do
        perform_and_refresh
      end
    end
  end
end

