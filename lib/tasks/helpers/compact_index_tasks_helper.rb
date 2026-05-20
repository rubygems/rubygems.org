# frozen_string_literal: true

module CompactIndexTasksHelper
  module_function

  def update_last_checksum(rubygem, task)
    last_version = rubygem.versions.order(Arel.sql("COALESCE(yanked_at, created_at) desc, number desc, platform desc")).first
    gem_info = GemInfo.new(last_version.rubygem.name)

    CompactIndex.active_formats.each do |format|
      cs = Digest::MD5.hexdigest(CompactIndex.info(gem_info.compact_index_info_for(format)))
      col = last_version.indexed ? format.checksum_column : format.yanked_checksum_column

      Rails.logger.info("[#{task}] version: #{last_version.full_name} format: #{format.version_key} old_checksum: #{last_version[col]} new_checksum: #{cs}")
      last_version.update_columns(col => cs)
    end
  end
end
