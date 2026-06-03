# frozen_string_literal: true

require "test_helper"

class UpdateVersionsListJobTest < ActiveJob::TestCase
  setup do
    @v1_file = Tempfile.new("versions_file")
    @v2_file = Tempfile.new("versions_v2_file")
    @original_v1_path = Rails.application.config.rubygems["versions_file_location"]
    @original_v2_path = Rails.application.config.rubygems["versions_file_location_v2"]
    Rails.application.config.rubygems["versions_file_location"] = @v1_file.path
    Rails.application.config.rubygems["versions_file_location_v2"] = @v2_file.path
    RubygemFs.instance.remove("versions/versions.list", "versions/versions_v2.list")
  end

  teardown do
    Rails.application.config.rubygems["versions_file_location"] = @original_v1_path
    Rails.application.config.rubygems["versions_file_location_v2"] = @original_v2_path
    @v1_file.unlink
    @v2_file.unlink
  end

  test "updates the v1 baseline versions list" do
    rubygem = create(:rubygem, name: "rubyrubyruby")
    create(:version, rubygem:, number: "0.0.1", info_checksum: "v1_checksum")

    freeze_time do
      UpdateVersionsListJob.perform_now(version: 1)
    end

    expected_line = "rubyrubyruby 0.0.1 v1_checksum\n"
    assert_equal expected_line, @v1_file.readlines[2]
    assert_includes RubygemFs.instance.get("versions/versions.list"), expected_line
    assert_nil RubygemFs.instance.get("versions/versions_v2.list")
  end

  test "updates the v2 baseline versions list" do
    rubygem = create(:rubygem, name: "rubyrubyruby")
    create(:version, rubygem:, number: "0.0.1", info_checksum_v2: "v2_checksum")

    freeze_time do
      UpdateVersionsListJob.perform_now(version: 2)
    end

    expected_line = "rubyrubyruby 0.0.1 v2_checksum\n"
    assert_equal expected_line, @v2_file.readlines[2]
    assert_includes RubygemFs.instance.get("versions/versions_v2.list"), expected_line
    assert_nil RubygemFs.instance.get("versions/versions.list")
  end
end
