# frozen_string_literal: true

require "test_helper"

class RegenerateV2VersionsFileTest < ActiveSupport::TestCase
  include RakeTaskHelper
  include ActiveJob::TestHelper

  setup do
    @tmp_versions_file = Tempfile.new("tmp_v2_versions_file")
    @original_path = Rails.application.config.rubygems["versions_file_location_v2"]
    Rails.application.config.rubygems["versions_file_location_v2"] = @tmp_versions_file.path

    setup_rake_tasks("compact_index_v2.rake")
  end

  def regenerate_versions_file
    freeze_time do
      @created_at = Time.now.utc.iso8601
      Rake::Task["compact_index_v2:regenerate_versions_file"].invoke
    end
  end

  teardown do
    Rails.application.config.rubygems["versions_file_location_v2"] = @original_path
    @tmp_versions_file.unlink
  end

  context "file header" do
    setup do
      regenerate_versions_file
    end

    should "use today's timestamp as header" do
      expected_header = "created_at: #{@created_at}\n---\n"

      assert_equal expected_header, @tmp_versions_file.read
    end
  end

  context "file content" do
    setup do
      @rubygem = create(:rubygem, name: "rubyrubyruby")
      create(:version, rubygem: @rubygem, number: "0.0.1", created_at: 2.minutes.ago,
                       info_checksum_v2: "v2_13q4e1")
      create(:version, rubygem: @rubygem, number: "0.0.2", created_at: 1.minute.ago,
                       info_checksum_v2: "v2_qw212r")

      regenerate_versions_file
    end

    should "include both versions with the latest info_checksum_v2 in the local file" do
      expected_output = "rubyrubyruby 0.0.1,0.0.2 v2_qw212r\n"

      assert_equal expected_output, @tmp_versions_file.readlines[2]
    end

    should "upload the file to v2/versions in S3" do
      uploaded = RubygemFs.compact_index.get("v2/versions")

      assert_not_nil uploaded
      assert_includes uploaded, "rubyrubyruby 0.0.1,0.0.2 v2_qw212r"
    end

    should "enqueue a Fastly purge for s3-v2/versions" do
      assert_enqueued_with(job: FastlyPurgeJob, args: [key: "s3-v2/versions", soft: true])
    end
  end

  context "yanked version" do
    setup do
      @rubygem = create(:rubygem, name: "rubyrubyruby")
      create(:version, rubygem: @rubygem, number: "0.0.1", created_at: 5.minutes.ago,
                       info_checksum_v2: "v2_qw212r")
      create(:version, indexed: false, rubygem: @rubygem, number: "0.0.2",
                       created_at: 3.minutes.ago, yanked_at: 1.minute.ago,
                       info_checksum_v2: "v2_sd12q",
                       yanked_info_checksum_v2: "v2_yanked")

      regenerate_versions_file
    end

    should "not include yanked version, but use yanked_info_checksum_v2" do
      expected_output = "rubyrubyruby 0.0.1 v2_yanked\n"

      assert_equal expected_output, @tmp_versions_file.readlines[2]
    end
  end

  context "gem missing info_checksum_v2" do
    setup do
      @rubygem = create(:rubygem, name: "rubyrubyruby")
      create(:version, rubygem: @rubygem, number: "0.0.1", info_checksum_v2: nil, created_at: 2.minutes.ago)
    end

    should "raise and not upload" do
      RubygemFs.compact_index.remove("v2/versions")

      error = assert_raises(RuntimeError) { regenerate_versions_file }

      assert_match(/missing info_checksum_v2/, error.message)
      assert_nil RubygemFs.compact_index.get("v2/versions")
    end
  end
end
