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
    v2_file&.unlink
  end

  test "discards unsupported versions" do
    assert_nothing_raised do
      UpdateVersionsListJob.perform_now(version: 1)
    end
  end
end
