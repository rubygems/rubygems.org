# frozen_string_literal: true

require "test_helper"

class UpdateVersionsFileTest < ActiveSupport::TestCase
  include RakeTaskHelper

  COMPACT_INDEX_VERSION_CONFIG = {
    2 => {
      config_key: "versions_file_location_v2",
      rake_task: "compact_index:update_versions_file",
      store_key: "versions/versions_v2.list",
      absent_store_keys: ["versions/versions.list"],
      checksum_column: :info_checksum_v2,
      yanked_checksum_column: :yanked_info_checksum_v2
    }
  }.freeze

  setup do
    @tmp_versions_files = {}
    @original_paths = {}

    COMPACT_INDEX_VERSION_CONFIG.each do |version, config|
      tmp_versions_file = Tempfile.new("versions_v#{version}.list")
      tmp_versions_file.write "created_at: 2015-08-23T17:22:53-07:00\n---\n"
      tmp_versions_file.close

      @tmp_versions_files[version] = tmp_versions_file
      @original_paths[config.fetch(:config_key)] = Rails.application.config.rubygems[config.fetch(:config_key)]
      Rails.application.config.rubygems[config.fetch(:config_key)] = tmp_versions_file.path
    end

    cleanup_compact_index_files
    setup_rake_tasks("compact_index.rake")
  end

  teardown do
    COMPACT_INDEX_VERSION_CONFIG.each_value do |config|
      Rails.application.config.rubygems[config.fetch(:config_key)] = @original_paths.fetch(config.fetch(:config_key))
    end
    cleanup_compact_index_files
    @tmp_versions_files.each_value(&:unlink)
  end

  COMPACT_INDEX_VERSION_CONFIG.each do |version, config|
    should "update compact index v#{version} versions file" do
      rubygem = create(:rubygem, name: "foo")
      create(:version,
        rubygem:,
        number: "1.0.0",
        created_at: 1.minute.ago,
        config.fetch(:checksum_column) => "v#{version}_checksum")

      Rake::Task[config.fetch(:rake_task)].invoke

      content = File.read(@tmp_versions_files.fetch(version).path)

      assert_includes content, "foo 1.0.0 v#{version}_checksum"
      assert_includes RubygemFs.instance.get(config.fetch(:store_key)), "foo 1.0.0 v#{version}_checksum"
      config.fetch(:absent_store_keys).each do |store_key|
        assert_nil RubygemFs.instance.get(store_key)
      end
    end

    should "use compact index v#{version} yanked checksum for latest yanked version" do
      rubygem = create(:rubygem, name: "foo")
      create(:version,
        rubygem:,
        number: "1.0.0",
        created_at: 2.minutes.ago,
        config.fetch(:checksum_column) => "v#{version}_checksum")
      create(:version,
        :yanked,
        rubygem:,
        number: "1.0.1",
        created_at: 90.seconds.ago,
        yanked_at: 1.minute.ago,
        config.fetch(:checksum_column) => "v#{version}_checksum",
        config.fetch(:yanked_checksum_column) => "v#{version}_yanked_checksum")

      Rake::Task[config.fetch(:rake_task)].invoke

      content = File.read(@tmp_versions_files.fetch(version).path)

      assert_includes content, "foo 1.0.0 v#{version}_yanked_checksum"
      assert_includes RubygemFs.instance.get(config.fetch(:store_key)), "foo 1.0.0 v#{version}_yanked_checksum"
      config.fetch(:absent_store_keys).each do |store_key|
        assert_nil RubygemFs.instance.get(store_key)
      end
    end
  end

  should "delegate the default compact index versions file task to the current version" do
    current_version = GemInfo::CURRENT_VERSION
    config = COMPACT_INDEX_VERSION_CONFIG.fetch(current_version)
    rubygem = create(:rubygem, name: "foo")
    create(:version,
      rubygem:,
      number: "1.0.0",
      created_at: 1.minute.ago,
      config.fetch(:checksum_column) => "current_checksum")

    Rake::Task["compact_index:update_versions_file"].invoke

    content = File.read(@tmp_versions_files.fetch(current_version).path)

    assert_includes content, "foo 1.0.0 current_checksum"
    assert_includes RubygemFs.instance.get(config.fetch(:store_key)), "foo 1.0.0 current_checksum"
    config.fetch(:absent_store_keys).each do |store_key|
      assert_nil RubygemFs.instance.get(store_key)
    end
  end

  private

  def cleanup_compact_index_files
    RubygemFs.instance.remove(*COMPACT_INDEX_VERSION_CONFIG.values.flat_map do |config|
      [config.fetch(:store_key), *config.fetch(:absent_store_keys)]
    end.uniq)
  end
end
