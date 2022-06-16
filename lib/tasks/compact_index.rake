require "tasks/helpers/compact_index_tasks_helper"

namespace :compact_index do
  def yanked_at_time(version)
    query = ["SELECT created_at FROM deletions,
      (SELECT name, number FROM versions, rubygems WHERE versions.rubygem_id = rubygems.id
        AND versions.id = ?) AS rv
      WHERE deletions.number = rv.number AND deletions.rubygem = rv.name", version.id]
    sanitize_sql = ActiveRecord::Base.send(:sanitize_sql_array, query)
    pg_result = ActiveRecord::Base.connection.execute(sanitize_sql)
    return pg_result.first["created_at"] if pg_result.first.present?
    Time.now.utc
  end

  desc "Fill yanked_at with current time"
  task backfill_yanked_at: :environment do
    without_yanked_at = Version.where(indexed: false, yanked_at: nil)
    mod = ENV["shard"]
    without_yanked_at = without_yanked_at.where("id % 4 = ?", mod.to_i) if mod

    total = without_yanked_at.count
    i = 0
    puts "Total: #{total}"
    without_yanked_at.find_each do |version|
      version.update_attribute :yanked_at, yanked_at_time(version)
      i += 1
      print format("\r%.2f%% (%d/%d) complete", i.to_f / total * 100.0, i, total)
    end
    puts
    puts "Done."
  end

  desc "Correct Versions' info_checksum attributes for compact index format"
  task correct_info_checksum: :environment do |task|
    compact_index_versions = GemInfo.compact_index_public_versions

    i        = 0
    mismatch = 0
    total    = compact_index_versions.count

    puts "Total: #{total}"
    compact_index_versions.each do |compact_index_gem|
      gem_name = compact_index_gem.name
      gem_info_checksum = compact_index_gem.versions.last.info_checksum

      cur_info_checksum = GemInfo.new(gem_name).info_checksum

      if cur_info_checksum != gem_info_checksum
        mismatch += 1
        rubygem = Rubygem.find_by(name: gem_name)
        CompactIndexTasksHelper.update_last_checksum(rubygem, task)
      end
      i += 1
      print format("\r%.2f%% (%d/%d) complete", i.to_f / total * 100.0, i, total)
    end
    Rails.logger.info("[compact_index:correct_info_checksum] #{mismatch}/#{total} gems had info mismatch")
  end

  desc "Fill Versions' yanked_info_checksum attributes for compact index format"
  task backfill_yanked_info_checksum: :environment do
    without_yanked_info_checksum = Version.where(indexed: false, yanked_info_checksum: nil)
    mod = ENV["shard"]
    without_yanked_info_checksum = without_yanked_info_checksum.where("id % 4 = ?", mod.to_i) if mod

    total = without_yanked_info_checksum.count
    i = 0
    puts "Total: #{total}"
    without_yanked_info_checksum.find_each do |version|
      cs = GemInfo.new(version.rubygem.name).info_checksum
      version.update_attribute :yanked_info_checksum, cs
      i += 1
      print format("\r%.2f%% (%d/%d) complete", i.to_f / total * 100.0, i, total)
    end
    puts
    puts "Done."
  end

  desc "Generate/update the versions.list file"
  task update_versions_file: :environment do
    ts            = Time.now.utc.iso8601
    file_path     = Rails.application.config.rubygems["versions_file_location"]
    versions_file = CompactIndex::VersionsFile.new file_path
    gems          = GemInfo.compact_index_public_versions ts

    versions_file.create gems, ts

    version_file_content = File.read(file_path)
    RubygemFs.instance.store("versions/versions.list", version_file_content)
  end

  desc "Update info checksum for multiple ruby or rubygems requirements"
  task multi_req_checksum: :environment do |task|
    ActiveRecord::Base.logger.level = 1 if Rails.env.development?

    versions_multi_req = Version.where("required_ruby_version like '%,%' or required_rubygems_version like '%,%'")

    total = versions_multi_req.count
    i = 0
    puts "Total: #{total}"
    versions_multi_req.each do |version|
      CompactIndexTasksHelper.update_last_checksum(version.rubygem, task)
      i += 1
      print format("\r%.2f%% (%d/%d) complete", i.to_f / total * 100.0, i, total)
    end
  end
end
