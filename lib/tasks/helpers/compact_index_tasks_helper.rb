module CompactIndexTasksHelper
  module_function

  def update_last_checksum(rubygem, task)
    last_version = rubygem.versions.order(Arel.sql("COALESCE(yanked_at, created_at) desc, number desc, platform desc")).first

    gem_info = GemInfo.new(last_version.rubygem.name).compact_index_info
    cs = Digest::MD5.hexdigest(CompactIndex.info(gem_info))

    if last_version.indexed
      Rails.logger.info("[#{task}] version: #{last_version.full_name} old_checksum: #{last_version.info_checksum} new_checksum: #{cs}")
      last_version.update_attribute :info_checksum, cs
    else
      Rails.logger.info("[#{task}] version: #{last_version.full_name} old_checksum: #{last_version.yanked_info_checksum} new_checksum: #{cs}")
      last_version.update_attribute :yanked_info_checksum, cs
    end
  end
end
