# frozen_string_literal: true

namespace :compact_index_v2 do
  desc "Generate/update the baseline v2 versions.list file"
  task update_versions_file: :environment do
    ts = Time.now.utc.iso8601
    file_path = Rails.application.config.rubygems["versions_file_location_v2"]
    versions_file = CompactIndex::VersionsFile.new(file_path)
    gems = GemInfo.compact_index_public_versions(ts, version: 2)

    versions_file.create(gems, ts)
    version_file_content = File.read(file_path)

    RubygemFs.instance.store("versions/versions_v2.list", version_file_content)
  end
end
