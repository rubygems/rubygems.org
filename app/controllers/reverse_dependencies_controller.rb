class ReverseDependenciesController < ApplicationController
  include LatestVersion
  before_action :find_rubygem, only: [:index]
  before_action :latest_version, only: [:index]
  before_action :set_page, only: [:index]
  before_action :find_versioned_links, only: [:index]

  def index
    cache_key = "reverse_dep/#{@rubygem.name}/#{@page}"
    @reverse_dependencies = if (rubygem_ids = Rails.cache.read(cache_key))
      StatsD.increment 'reverse_dependencies.memcached.hit'
      Rubygem.where(id: rubygem_ids).by_downloads.page(page).without_count
    else
      StatsD.increment 'reverse_dependencies.memcached.miss'
      reverse_dependencies_from_db
    end

    _, @reverse_dependencies = @reverse_dependencies.search(params[:rdeps_query]) if params[:rdeps_query]&.is_a?(String)
    preload_associations
  end

  private

  def reverse_dependencies_from_db
    offset = Rubygem.default_per_page * (page - 1)
    limit = offset + Rubygem.default_per_page + 1
    dependencies = @rubygem.reverse_dependencies_by_downloads(offset, limit)
    Rails.cache.write(cache_key, dependencies.map(&:id).map(&:to_s), expires_in: Gemcutter::REVERSE_DEP_EXPIRES_IN)
    Kaminari.paginate_array(dependencies).page(page).per(Rubygem.default_per_page)
  end

  def preload_associations
    ActiveRecord::Associations::Preloader.new.preload(@reverse_dependencies, :gem_download)
    ActiveRecord::Associations::Preloader.new.preload(@reverse_dependencies, :latest_version)
  end
end
