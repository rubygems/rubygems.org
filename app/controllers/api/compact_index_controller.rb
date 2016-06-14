class Api::CompactIndexController < Api::BaseController
  before_action :find_rubygem_by_name, only: [:info]

  def names
    names = Rubygem.ordered_names
    response_body = CompactIndex.names(names)
    requested_range_for(response_body)
  end

  def versions
    versions_file_location = Rails.application.config.rubygems['versions_file_location']
    versions_file = CompactIndex::VersionsFile.new(versions_file_location)
    from_date = versions_file.updated_at
    extra_gems = Rubygem.compact_index_versions(from_date)
    response_body = CompactIndex.versions(versions_file, extra_gems)
    requested_range_for(response_body)
  end

  def info
    return unless stale?(@rubygem)
    info_params = @rubygem.compact_index_info
    response_body = CompactIndex.info(info_params)
    requested_range_for(response_body)
  end

  private

  def requested_range_for(response_body)
    ranges = Rack::Utils.byte_ranges(env, response_body.bytesize)

    if ranges
      response = ranges.map { |range| response_body.byteslice(range) }.join
      render status: 206, plain: response
    else
      render status: 200, plain: response_body
    end
  end
end
