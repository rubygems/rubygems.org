require 'test_helper'

class FastlyLogProcessorTest < ActiveSupport::TestCase

  setup do
    @sample_log = File.read(Rails.root.join('test/sample_logs/fastly-fake.log'))

    @sample_log_counts = {
      "bundler-1.10.6"=>2,
      "json-1.8.3-java"=>2,
      "json-1.8.3"=>1,
      "json-1.8.2"=>3,
      "no-such-gem-1.2.3"=>1
    }

    Aws.config[:s3] = {
      stub_responses: { get_object: { body: @sample_log } }
    }
    @job = FastlyLogProcessor.new('test-bucket', 'fastly-fake.log')
  end

  teardown do
    # Remove stubbed response
    Aws.config.delete(:s3)
  end

  context "#s3_body" do
    should "return a readable object " do
      assert @job.s3_body.respond_to?(:read)
    end
  end

  context "#log_lines" do
    should "return an enumerator" do
      assert_kind_of Enumerator, @job.log_lines
    end

    should "have values" do
      assert @job.log_lines.first
    end
  end

  context "#download_counts" do
    should "be correct" do
      assert_equal @sample_log_counts, @job.download_counts
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
          ["json", "json-1.8.2", 3]
          # No entry for `no-such-gem`
        ]

        assert_equal expected, @job.munge_for_bulk_update(@sample_log_counts)
      end
    end

    context '#perform' do
      should "update download counts" do
        @job.perform

        @sample_log_counts.
          reject{|k,_| k == "no-such-gem-1.2.3"}.
          each do |name, expected_count|
          assert_equal expected_count, Version.find_by_full_name(name).downloads_count
        end

        assert_equal 6, Rubygem.find_by_name('json').downloads

      end

      should 'set the redis key' do
        @job.perform
        assert_equal 'processed', Redis.current.get(@job.redis_key)
        assert_in_delta Redis.current.ttl(@job.redis_key), 30.days, 10
      end

      should "fail if already run" do
        Redis.current.set(@job.redis_key, 'processed')
        assert_raises(FastlyLogProcessor::AlreadyProcessedError) { @job.perform }
      end
    end
  end

end
