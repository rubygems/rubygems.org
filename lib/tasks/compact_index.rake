namespace :compact_index do
  def yanked_at_time(version)
    query = ["SELECT created_at FROM deletions,
      (SELECT name, number FROM versions, rubygems WHERE versions.rubygem_id = rubygems.id
        AND versions.id = ?) AS rv
      WHERE deletions.number = rv.number AND deletions.rubygem = rv.name", version.id]
    sanitize_sql = ActiveRecord::Base.send(:sanitize_sql_array, query)
    pg_result = ActiveRecord::Base.connection.execute(sanitize_sql)
    return pg_result.first['created_at'] if pg_result.first.present?
    Time.now.utc
  end

  desc "Fill yanked_at with current time"
  task backfill_yanked_at: :environment do
    without_yanked_at = Version.where(indexed: false)
    mod = ENV['shard']
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

  desc "Fill Versions' info_checksum attributes for compact index format"
  task backfill_info_checksum: :environment do
    without_info_checksum = Rubygem.joins('inner join versions on rubygems.id = versions.rubygem_id')
      .where('versions.info_checksum is null')
      .distinct
    mod = ENV['shard']
    without_info_checksum = without_info_checksum.where("id % 4 = ?", mod.to_i) if mod

    total = without_info_checksum.count
    i = 0
    puts "Total: #{total}"

    without_info_checksum.find_each do |rubygem|
      cs = Digest::MD5.hexdigest(CompactIndex.info(rubygem.compact_index_info))
      rubygem.versions.each do |version|
        version.update_attribute :info_checksum, cs
      end
      i += 1
      print format("\r%.2f%% (%d/%d) complete", i.to_f / total * 100.0, i, total)
    end
    puts
    puts "Done."
  end
end
