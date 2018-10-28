class ReverseDependenciesController < ApplicationController
  include LatestVersion
  before_action :find_rubygem,
    :latest_version,
    :set_page,
    :find_versioned_links,
    :set_offset_and_limit

  def index
    cache_key = "reverse_dep/#{@rubygem.name}/#{@page}"
    @reverse_dependencies =
      if (rubygem_ids = Rails.cache.read(cache_key))
        StatsD.increment 'reverse_dependencies.memcached.hit'
        Rubygem.where(id: rubygem_ids).by_downloads.page(@page).without_count
      else
        StatsD.increment 'reverse_dependencies.memcached.miss'
        reverse_dependencies_from_db(cache_key)
      end
    preload_associations
  end

  def search
    query = params[:rdeps_query].to_s

    dependencies = ReverseDependency.new(@rubygem.id).search(query, @offset, @limit)
    @reverse_dependencies = Kaminari.paginate_array(dependencies).page(@page).per(Rubygem.default_per_page)
    preload_associations
    render :index
  end

  private

  def reverse_dependencies_from_db(cache_key)
    dependencies = ReverseDependency.new(@rubygem.id).by_downloads(@offset, @limit)
    Rails.cache.write(cache_key, dependencies.map(&:id).map(&:to_s), expires_in: Gemcutter::REVERSE_DEP_EXPIRES_IN)
    Kaminari.paginate_array(dependencies).page(@page).per(Rubygem.default_per_page)
  end

  def set_offset_and_limit
    @offset = Rubygem.default_per_page * (@page - 1)
    @limit = @offset + Rubygem.default_per_page + 1
  end

  def preload_associations
    ActiveRecord::Associations::Preloader.new.preload(@reverse_dependencies, :gem_download)
    ActiveRecord::Associations::Preloader.new.preload(@reverse_dependencies, :latest_version)
  end
end
