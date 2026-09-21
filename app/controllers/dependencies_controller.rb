# frozen_string_literal: true

class DependenciesController < ApplicationController
  include LatestVersion

  before_action :find_rubygem, only: [:show]
  before_action :latest_version_by_slug, only: [:show]
  before_action :find_versioned_links, only: [:show], if: -> { request.format.html? }

  layout "subject"

  def show
    @dependencies = Hash.new { |h, k| h[k] = [] }
    dependencies = @latest_version.dependencies
      .strict_loading.preload(rubygem: :public_versions_for_dependencies)

    dependencies.each do |dependency|
      if dependency.unresolved_name.nil? && dependency.rubygem
        gem_name = dependency.rubygem.name
        version = dep_resolver(gem_name, dependency, @latest_version.platform)
        @dependencies[dependency.scope] << [gem_name, version, dependency.requirements]
      else
        # unresolved dependencies have no gem page to link to; list them by name only
        @dependencies[dependency.scope] << [dependency.name, nil, dependency.requirements]
      end
    end

    respond_to do |format|
      format.json { render json: json_return }
      format.html do
        @reverse_dependencies = @rubygem.unique_reverse_dependencies.by_downloads
          .preload(:gem_download, :most_recent_version).limit(10)
        add_breadcrumbs
      end
    end
    set_surrogate_key "gem/#{@rubygem.name}/dependencies"
    cache_expiry_headers(expiry: 60, fastly_expiry: 60) if cacheable_request?
  end

  private

  def add_breadcrumbs
    add_breadcrumb @rubygem.name, rubygem_path(id: @rubygem.slug)
    if @latest_version == @rubygem.most_recent_version
      add_breadcrumb t("breadcrumbs.latest_version", version: @latest_version.slug), rubygem_path(id: @rubygem.slug)
    else
      add_breadcrumb @latest_version.slug, rubygem_version_path(rubygem_id: @rubygem.slug, id: @latest_version.slug)
    end
    add_breadcrumb t("rubygems.show.tabs.dependencies")
  end

  def dep_resolver(name, dependency, platform)
    requirements = dependency.clean_requirements
    reqs = Gem::Dependency.new(name, requirements.split(/\s*,\s*/))

    matching_versions = dependency.rubygem.public_versions_for_dependencies.select { |v| reqs.match?(name, v.number) }
    match = matching_versions.detect { |v| match_platform?(platform, v.platform) } || matching_versions.first
    match&.slug
  end

  def match_platform?(platform, dep_platform)
    Gem::Platform.new(platform) == Gem::Platform.new(dep_platform)
  end

  def json_return
    {
      run_html: render_str_call("runtime"),
      dev_html: render_str_call("development")
    }
  end

  def render_str_call(scope)
    local_var = { scope: scope, dependencies: @dependencies, gem_name: @latest_version.rubygem.name }
    self.class.renderer.new(request.env).render(partial: "dependencies/dependencies", formats: [:html], locals: local_var)
  end
end
