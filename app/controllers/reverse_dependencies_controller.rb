# frozen_string_literal: true

class ReverseDependenciesController < ApplicationController
  include LatestVersion

  before_action :find_rubygem, only: [:index]
  before_action :latest_version, only: [:index]
  before_action :set_page, only: [:index]
  before_action :find_versioned_links, only: [:index]

  def index
    @reverse_dependencies = @rubygem.unique_reverse_dependencies
      .by_downloads
      .preload(:gem_download, :latest_version)

    @reverse_dependencies = @reverse_dependencies.legacy_search(params[:rdeps_query]) if params[:rdeps_query].is_a?(String)
    @reverse_dependencies = @reverse_dependencies.page(@page).without_count
    set_surrogate_key "gem/#{@rubygem.name}/reverse_dependencies"
    cache_expiry_headers(expiry: 60, fastly_expiry: 60) if cacheable_request?
  end
end
