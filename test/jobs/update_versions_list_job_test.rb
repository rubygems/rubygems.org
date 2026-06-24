# frozen_string_literal: true

require "test_helper"

class UpdateVersionsListJobTest < ActiveJob::TestCase
  test "updates the v2 baseline versions list" do
    v2_file = Tempfile.new("versions_v2_file")
    original_v2_path = Rails.application.config.rubygems["versions_file_location_v2"]
    Rails.application.config.rubygems["versions_file_location_v2"] = v2_file.path
    RubygemFs.instance.remove("versions/versions.list", "versions/versions_v2.list")

    rubygem = create(:rubygem, name: "rubyrubyruby")
    create(:version, rubygem:, number: "0.0.1", created_at: 1.minute.ago, info_checksum_v2: "v2_checksum")

    freeze_time do
      UpdateVersionsListJob.perform_now(version: 2)
    end

    expected_line = "rubyrubyruby 0.0.1 v2_checksum\n"

    assert_equal expected_line, File.readlines(v2_file.path)[2]
    assert_includes RubygemFs.instance.get("versions/versions_v2.list"), expected_line
    assert_nil RubygemFs.instance.get("versions/versions.list")
  ensure
    Rails.application.config.rubygems["versions_file_location_v2"] = original_v2_path
    RubygemFs.instance.remove("versions/versions.list", "versions/versions_v2.list")
    v2_file&.unlink
  end

  test "discards unsupported versions" do
    assert_nothing_raised do
      UpdateVersionsListJob.perform_now(version: 1)
    end
  end

  test "discards invalid versions" do
    assert_nothing_raised do
      UpdateVersionsListJob.perform_now(version: "not-a-version")
    end
  end

  test "logs when discarding unsupported versions" do
    logger = mock
    logger.expects(:info).with(
      message: "Discarding update versions list job",
      error: "Unsupported compact index version: 1",
      version: 1
    )

    job = UpdateVersionsListJob.new(version: 1)
    job.stubs(:logger).returns(logger)

    assert_nothing_raised do
      job.perform_now
    end
  end
end
