# frozen_string_literal: true

class VersionsController < ApplicationController
  before_action :find_rubygem

  def index
    set_page
    @oldest_version_date = @rubygem.versions.oldest_authored_at
    @versions = @rubygem.versions.by_position.page(@page).per(Gemcutter::VERSIONS_PER_PAGE)
    set_surrogate_key "gem/#{@rubygem.name}/versions"
    cache_expiry_headers(expiry: 60, fastly_expiry: 60) if cacheable_request?
  end

  def show
    @latest_version  = @rubygem.find_version_by_slug!(params[:id])
    @versions        = @rubygem.public_versions_with_extra_version(@latest_version)
    @versioned_links = @rubygem.links(@latest_version)
    @on_version_page = true
    render "rubygems/show"
    set_surrogate_key "gem/#{@rubygem.name}"
    cache_expiry_headers(expiry: 60, fastly_expiry: 60) if cacheable_request?
  end
end
