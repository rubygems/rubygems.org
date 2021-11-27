require "test_helper"

class FastlyLogProcessorTest < ActiveSupport::TestCase
  include ESHelper

  setup do
    @sample_log = Rails.root.join("test", "sample_logs", "fastly-fake.log").read

    @sample_log_counts = {
      "bundler-1.10.6" => 2,
      "json-1.8.3-java" => 2,
      "json-1.8.3" => 1,
      "json-1.8.2" => 4,
      "no-such-gem-1.2.3" => 1
    }
    @log_ticket = LogTicket.create!(backend: "s3", directory: "test-bucket", key: "fastly-fake.log", status: "pending")

    Aws.config[:s3] = {
      stub_responses: { get_object: { body: @sample_log } }
    }
    @job = FastlyLogProcessor.new("test-bucket", "fastly-fake.log")
    create(:gem_download)
    Rubygem.__elasticsearch__.create_index! force: true
  end

  teardown do
    # Remove stubbed response
    Aws.config.delete(:s3)
  end

  context "#download_counts" do
    should "process file from s3" do
      assert_equal @sample_log_counts, @job.download_counts(@log_ticket)
    end

    should "process file from local fs" do
      @log_ticket.update(backend: "local", directory: "test/sample_logs")
      assert_equal @sample_log_counts, @job.download_counts(@log_ticket)
    end

    should "fail if dont find the file" do
      @log_ticket.update(backend: "local", directory: "foobar")
      assert_raises FastlyLogProcessor::LogFileNotFoundError do
        @job.download_counts(@log_ticket)
      end
    end
  end

  context "with gem data" do
    setup do
      # Create some gems to match the values in the sample log
      bundler = create(:rubygem, name: "bundler")
      json = create(:rubygem, name: "json")

      create(:version, rubygem: bundler, number: "1.10.6")
      create(:version, rubygem: json, number: "1.8.3", platform: "java")
      create(:version, rubygem: json, number: "1.8.3")
      create(:version, rubygem: json, number: "1.8.2")

      import_and_refresh
    end

    context "#perform" do
      should "not double count" do
        json = Rubygem.find_by_name("json")
        assert_equal 0, GemDownload.count_for_rubygem(json.id)
        3.times { @job.perform }
        assert_equal 7, es_downloads(json.id)
        assert_equal 7, GemDownload.count_for_rubygem(json.id)
      end

      should "update download counts" do
        @job.perform
        @sample_log_counts
          .each do |name, expected_count|
          version = Version.find_by(full_name: name)
          if version
            count = GemDownload.find_by(rubygem_id: version.rubygem.id, version_id: version.id).count
            assert_equal expected_count, count, "invalid value for #{name}"
          end
        end

        json = Rubygem.find_by_name("json")
        assert_equal 7, GemDownload.count_for_rubygem(json.id)
        assert_equal 7, es_downloads(json.id)
        assert_equal "processed", @log_ticket.reload.status
      end

      should "not run if already processed" do
        json = Rubygem.find_by_name("json")
        assert_equal 0, json.downloads
        assert_equal 0, es_downloads(json.id)
        @log_ticket.update(status: "processed")
        @job.perform

        assert_equal 0, es_downloads(json.id)
        assert_equal 0, json.downloads
      end

      should "not mark as processed if anything fails" do
        @job.stubs(:download_counts).raises("woops")
        assert_raises(RuntimeError) { @job.perform }

        refute_equal "processed", @log_ticket.reload.status
        assert_equal "failed", @log_ticket.reload.status
      end

      should "not re-process if it failed" do
        @job.stubs(:download_counts).raises("woops")
        assert_raises(RuntimeError) { @job.perform }

        @job = FastlyLogProcessor.new("test-bucket", "fastly-fake.log")
        @job.perform
        json = Rubygem.find_by_name("json")
        assert_equal 0, json.downloads
        assert_equal 0, es_downloads(json.id)
      end

      should "only process the right file" do
        ticket = LogTicket.create!(backend: "s3", directory: "test-bucket", key: "fastly-fake.2.log", status: "pending")

        @job.perform
        assert_equal "pending", ticket.reload.status
        assert_equal "processed", @log_ticket.reload.status
      end

      should "update the processed count" do
        @job.perform
        assert_equal 10, @log_ticket.reload.processed_count
      end

      should "update the total gem count" do
        assert_equal 0, GemDownload.total_count
        @job.perform
        assert_equal 9, GemDownload.total_count
      end
    end
  end
end
