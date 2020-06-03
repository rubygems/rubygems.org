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
  task correct_info_checksum: :environment do
    versions = Version.find_by_sql("SELECT DISTINCT ON(rubygem_id) * FROM versions
      WHERE rubygem_id NOT IN (SELECT DISTINCT(rubygem_id) FROM versions
      WHERE created_at > '2016-08-30 05:16:23' OR yanked_at > '2016-08-30 05:16:23')
      ORDER BY rubygem_id, COALESCE(yanked_at, created_at) DESC, number DESC, platform DESC")
    mod = ENV["shard"]
    versions = versions.where("id % 4 = ?", mod.to_i) if mod

    total = versions.count
    i = 0
    puts "Total: #{total}"

    versions.each do |version|
      gem_info = GemInfo.new(version.rubygem.name).compact_index_info
      cs = Digest::MD5.hexdigest(CompactIndex.info(gem_info))
      if version.indexed
        version.update_attribute :info_checksum, cs
      else
        version.update_attribute :yanked_info_checksum, cs
      end
      i += 1
      print format("\r%.2f%% (%d/%d) complete", i.to_f / total * 100.0, i, total)
    end
    puts
    puts "Done."
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
      cs = Digest::MD5.hexdigest(CompactIndex.info(GemInfo.new(version.rubygem.name).compact_index_info))
      version.update_attribute :yanked_info_checksum, cs
      i += 1
      print format("\r%.2f%% (%d/%d) complete", i.to_f / total * 100.0, i, total)
    end
    puts
    puts "Done."
  end

  desc "Generate/update the versions.list file"
  task update_versions_file: :environment do
    file_path = Rails.application.config.rubygems["versions_file_location"]
    versions_file = CompactIndex::VersionsFile.new file_path
    gems = GemInfo.compact_index_public_versions

    versions_file.create gems

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
