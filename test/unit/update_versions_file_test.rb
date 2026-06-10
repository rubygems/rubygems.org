# frozen_string_literal: true

require "test_helper"
require "rake"

class UpdateVersionsFileTest < ActiveSupport::TestCase
  setup do
    @tmp_versions_file = Tempfile.new("versions_v2.list")
    @tmp_versions_file.write "created_at: 2015-08-23T17:22:53-07:00\n---\n"
    @tmp_versions_file.close

    @original_path = Rails.application.config.rubygems["versions_file_location_v2"]
    Rails.application.config.rubygems["versions_file_location_v2"] = @tmp_versions_file.path
    setup_rake_tasks("compact_index_v2.rake", "compact_index.rake")
  end

  teardown do
    Rake::Task["compact_index:update_versions_file"].reenable
    Rake::Task["compact_index_v2:update_versions_file"].reenable
    Rails.application.config.rubygems["versions_file_location_v2"] = @original_path
    @tmp_versions_file.unlink
  end

  should "delegate the default compact index versions file task to v2" do
    RubygemFs.instance.remove("versions/versions.list", "versions/versions_v2.list")

    rubygem = create(:rubygem, name: "foo")
    create(:version, rubygem:, number: "1.0.0", info_checksum_v2: "v2_checksum")

    Rake::Task["compact_index:update_versions_file"].invoke

    content = File.read(@tmp_versions_file.path)

    assert_includes content, "foo 1.0.0 v2_checksum"
    assert_includes RubygemFs.instance.get("versions/versions_v2.list"), "foo 1.0.0 v2_checksum"
    assert_nil RubygemFs.instance.get("versions/versions.list")
  end

  should "use yanked_info_checksum_v2 for yanked versions" do
    RubygemFs.instance.remove("versions/versions.list", "versions/versions_v2.list")

    rubygem = create(:rubygem, name: "foo")
    create(:version,
      :yanked,
      rubygem:,
      number: "1.0.0",
      info_checksum_v2: "v2_checksum",
      yanked_info_checksum_v2: "v2_yanked_checksum")

    Rake::Task["compact_index:update_versions_file"].invoke

    content = File.read(@tmp_versions_file.path)

    assert_includes content, "foo -1.0.0 v2_yanked_checksum"
    assert_includes RubygemFs.instance.get("versions/versions_v2.list"), "foo -1.0.0 v2_yanked_checksum"
    assert_nil RubygemFs.instance.get("versions/versions.list")
  end
end
