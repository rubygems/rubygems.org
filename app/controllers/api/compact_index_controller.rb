class Api::CompactIndexController < Api::BaseController
  before_action :find_rubygem_by_name, only: [:info]

  def names
    names = Rubygem.ordered_names
    render_range CompactIndex.names(names)
  end

  def versions
    versions_path = Rails.application.config.rubygems['versions_file_location']
    versions_file = CompactIndex::VersionsFile.new(versions_path)
    from_date = versions_file.updated_at
    extra_gems = Rubygem.compact_index_versions(versions_file.updated_at)
    render_range CompactIndex.versions(versions_file, extra_gems)
  end

  def info
    return unless stale?(@rubygem)
    info_params = @rubygem.compact_index_info
    render_range CompactIndex.info(info_params)
  end

  private

  def render_range(response_body)
    headers['ETag'] = '"' << Digest::MD5.hexdigest(response_body) << '"'

    ranges = Rack::Utils.byte_ranges(env, response_body.bytesize)
    if ranges
      response = ranges.map { |range| response_body.byteslice(range) }.join
      render status: 206, plain: response
    else
      render status: 200, plain: response_body
    end
  end

end
