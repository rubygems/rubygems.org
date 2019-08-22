class DependenciesController < ApplicationController
  include LatestVersion
  include RequirementsVersion

  def show
    latest_version_by_slug
    @dependencies = Hash.new { |h, k| h[k] = [] }

    @latest_version.dependencies.each do |dependency|
      gem_name = dependency.rubygem.name
      version = dep_resolver(
        gem_name,
        dependency["requirements"],
        dependency.rubygem.public_versions.pluck(:number)
      )
      @dependencies[dependency.scope] << [gem_name, version, dependency.requirements]
    end

    respond_to do |format|
      format.json { render json: json_return }
      format.html
    end
  end

  private

  def json_return
    {
      run_deps: @dependencies["runtime"],
      dev_deps: @dependencies["development"]
    }
  end
end
