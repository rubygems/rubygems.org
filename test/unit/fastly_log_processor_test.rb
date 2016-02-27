require 'test_helper'

class FastlyLogProcessorTest < ActiveSupport::TestCase
  setup do
    # Enable fastly log processing
    @orig_fastly_log_processor_enabled = ENV['FASTLY_LOG_PROCESSOR_ENABLED']
    ENV['FASTLY_LOG_PROCESSOR_ENABLED'] = 'true'

    @sample_log = Rails.root.join('test/sample_logs/fastly-fake.log').read

    @sample_log_counts = {
      "bundler-1.10.6" => 2,
      "json-1.8.3-java" => 2,
      "json-1.8.3" => 1,
      "json-1.8.2" => 4,
      "no-such-gem-1.2.3" => 1
    }
    @log_ticket = LogTicket.create!(backend: 's3', directory: 'test-bucket', key: 'fastly-fake.log', status: "pending")

    Aws.config[:s3] = {
      stub_responses: { get_object: { body: @sample_log } }
    }
    @job = FastlyLogProcessor.new('test-bucket', 'fastly-fake.log')
  end

  teardown do
    # Remove stubbed response
    Aws.config.delete(:s3)
    ENV['FASTLY_LOG_PROCESSOR_ENABLED'] = @orig_fastly_log_processor_enabled
  end

  context "#download_counts" do
    should "be correct" do
      assert_equal @sample_log_counts, @job.download_counts(@log_ticket)
    end
  end

  context "with gem data" do
    setup do
      # Create some gems to match the values in the sample log
      bundler = create(:rubygem, name: 'bundler')
      json = create(:rubygem, name: 'json')

      create(:version, rubygem: bundler, number: '1.10.6')
      create(:version, rubygem: json, number: '1.8.3', platform: 'java')
      create(:version, rubygem: json, number: '1.8.3')
      create(:version, rubygem: json, number: '1.8.2')
    end

    context "#munge_for_bulk_update" do
      should "exclude missing gems" do
        expected = [
          ["bundler", "bundler-1.10.6", 2],
          ["json", "json-1.8.3-java", 2],
          ["json", "json-1.8.3", 1],
          ["json", "json-1.8.2", 4]
          # No entry for `no-such-gem`
        ]

        assert_equal expected, @job.munge_for_bulk_update(@sample_log_counts)
      end
    end

    context '#perform' do
      should "update download counts" do
        @job.perform
        @sample_log_counts
          .reject { |k, _| k == "no-such-gem-1.2.3" }
          .each do |name, expected_count|
          assert_equal expected_count, Version.find_by_full_name(name).downloads_count, "invalid value for #{name}"
        end

        assert_equal 7, Rubygem.find_by_name('json').downloads
        assert_equal "processed", @log_ticket.reload.status
      end

      should "fail if already run" do
        @log_ticket.update(status: 'processed')
        @job.perform
      end
    end
  end
end
