namespace :compact_index do
  desc "Fill yanked_at with current time"
  task migrate_yanked_at: :environment do
    Version.where(yanked_at: nil).find_in_batches do |versions|
      versions.each { |v| v.update_attribute :yanked_at, Time.now.utc }
    end
  end

  desc "Fill Versions' info_checksum attributes for compact index format"
  task migrate: :environment do
    Rubygem.all.find_in_batches.each do |rubygem|
      cs = Digest::MD5.hexdigest(CompactIndex.info(rubygem.compact_index_info))
      rubygem.versions.each do |version|
        version.update_attribute :info_checksum, cs
      end
    end
  end
end
