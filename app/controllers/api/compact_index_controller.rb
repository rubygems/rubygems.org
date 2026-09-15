# frozen_string_literal: true

class Api::CompactIndexController < Api::BaseController
  COMPACT_INDEX_VERSIONS = {
    2 => {
      info_prefix: "v2/info",
      versions_file_location_key: "versions_file_location_v2",
      versions_surrogate_key: "v2/versions"
    }.freeze
  }.freeze

  before_action :find_rubygem_by_name, only: [:info]

  def names
    cache_expiry_headers
    names = GemInfo.ordered_names
    render_range CompactIndex.names(names)
  end

  def versions
    set_surrogate_key compact_index_versions_surrogate_key
    cache_expiry_headers
    versions_file = CompactIndex::VersionsFile.new(compact_index_versions_file_location)
    from_date = versions_file.updated_at
    extra_gems = GemInfo.compact_index_versions(from_date, version: GemInfo::CURRENT_VERSION)
    render_range CompactIndex.versions(versions_file, extra_gems)
  end

  def info
    info_prefix = compact_index_info_prefix

    set_surrogate_key "#{info_prefix}/* gem/#{@rubygem.name} #{info_prefix}/#{@rubygem.name}"
    cache_expiry_headers
    return unless stale?(etag: [@rubygem, GemInfo::CURRENT_VERSION])

    info_params = GemInfo.new(@rubygem.name).compact_index_info(version: GemInfo::CURRENT_VERSION)
    render_range CompactIndex.info(info_params)
  end

  private

  def compact_index_config
    @compact_index_config ||= COMPACT_INDEX_VERSIONS.fetch(GemInfo::CURRENT_VERSION)
  end

  def compact_index_versions_file_location
    Rails.application.config.rubygems[compact_index_config.fetch(:versions_file_location_key)]
  end

  def compact_index_versions_surrogate_key
    compact_index_config.fetch(:versions_surrogate_key)
  end

  def compact_index_info_prefix
    compact_index_config.fetch(:info_prefix)
  end

  def find_rubygem_by_name
    super
    return if @rubygem

    info_prefix = compact_index_info_prefix

    cache_expiry_headers(fastly_expiry: 600)
    set_surrogate_key "#{info_prefix}/404 #{info_prefix}/#{gem_name}"
  end

  def render_range(response_body)
    headers["ETag"] = %("#{Digest::MD5.hexdigest(response_body)}")
    digest = Digest::SHA256.base64digest(response_body)
    headers["Digest"] = "sha-256=#{digest}"
    headers["Repr-Digest"] = "sha-256=:#{digest}:"
    headers["Accept-Ranges"] = "bytes"
    headers["Content-Type"] = "text/plain; charset=utf-8"

    ranges = Rack::Utils.byte_ranges(request.env, response_body.bytesize)
    if ranges
      ranged_response = ranges.map { |range| response_body.byteslice(range) }.join
      render status: :partial_content, plain: ranged_response
    else
      render status: :ok, plain: response_body
    end
  end
end
