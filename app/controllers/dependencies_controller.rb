class DependenciesController < ApplicationController
  include LatestVersion
  before_action :find_rubygem, only: [:show]
  before_action :latest_version_by_slug, only: [:show]

  def show
    @dependencies = Hash.new { |h, k| h[k] = [] }
    resolvable_dependencies = @latest_version.dependencies.where(unresolved_name: nil)

    resolvable_dependencies.each do |dependency|
      gem_name = dependency.rubygem.name

      version = dep_resolver(gem_name, dependency, @latest_version.platform)
      @dependencies[dependency.scope] << [gem_name, version, dependency.requirements]
    end

    respond_to do |format|
      format.json { render json: json_return }
      format.html
    end
  end

  private

  def dep_resolver(name, dependency, platform)
    requirements = dependency.clean_requirements
    reqs = Gem::Dependency.new(name, requirements.split(/\s*,\s*/))

    matching_versions = dependency.rubygem.public_versions.select { |v| reqs.match?(name, v.number) }
    match = matching_versions.detect { |v| match_platform(platform, v.platform) } || matching_versions.first
    match&.slug
  end

  def match_platform(platform, dep_platform)
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
    ActionController::Base.new.render_to_string(partial: "dependencies/dependencies", formats: [:html], locals: local_var)
  end
end
