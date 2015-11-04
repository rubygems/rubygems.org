namespace :compact_index do
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
