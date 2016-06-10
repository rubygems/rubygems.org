class Api::CompactIndexController < Api::BaseController
  before_action :find_rubygem_by_name, only: [:info]

  def names
    names = Rubygem.order("name").pluck("name")
    render text: CompactIndex.names(names)
  end

  def versions
    versions_file_location = Rails.application.config.rubygems['versions_file_location']
    versions_file = CompactIndex::VersionsFile.new(versions_file_location)
    from_date = versions_file.updated_at
    extra_gems = Rubygem.compact_index_versions(from_date)
    render text: CompactIndex.versions(versions_file, extra_gems)
  end

  def info
    return unless stale?(@rubygem)
    info_params = @rubygem.compact_index_info
    render text: CompactIndex.info(info_params)
  end
end
