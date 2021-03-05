class Api::CompactIndexController < Api::BaseController
  before_action :find_rubygem_by_name, only: [:info]

  def names
    cache_expiry_headers
    names = GemInfo.ordered_names
    render_range CompactIndex.names(names)
  end

  def versions
    set_surrogate_key "versions"
    cache_expiry_headers(fastly_expiry: 30)
    versions_path = Rails.application.config.rubygems["versions_file_location"]
    versions_file = CompactIndex::VersionsFile.new(versions_path)
    from_date = versions_file.updated_at
    extra_gems = GemInfo.compact_index_versions(from_date)
    render_range CompactIndex.versions(versions_file, extra_gems)
  end

  def info
    set_surrogate_key "info/* gem/#{@rubygem.name} info/#{@rubygem.name}"
    cache_expiry_headers
    return unless stale?(@rubygem)
    info_params = GemInfo.new(@rubygem.name).compact_index_info
    render_range CompactIndex.info(info_params)
  end

  private

  def cache_expiry_headers(fastly_expiry: 3600)
    expires_in 60, public: true
    fastly_expires_in fastly_expiry
  end

  def render_range(response_body)
    headers["ETag"] = '"' << Digest::MD5.hexdigest(response_body) << '"'

    ranges = Rack::Utils.byte_ranges(request.env, response_body.bytesize)
    if ranges
      ranged_response = ranges.map { |range| response_body.byteslice(range) }.join
      render status: :partial_content, plain: ranged_response
    else
      render status: :ok, plain: response_body
    end
  end
end
