class DependenciesController < ApplicationController
  include LatestVersion
  include RequirementsVersion

  def show
    latest_version_by_slug
    @dependencies = Hash.new { |h, k| h[k] = [] }
    resolvable_dependencies = @latest_version.dependencies.where(unresolved_name: nil)

    resolvable_dependencies.each do |dependency|
      gem_name = dependency.rubygem.name

      version = dep_resolver(
        gem_name,
        dependency.clean_requirements,
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
      run_html: render_str_call("runtime"),
      dev_html: render_str_call("development")
    }
  end

  def render_str_call(scope)
    local_var = { scope: scope, dependencies: @dependencies, gem_name: @latest_version.rubygem.name }
    ActionController::Base.new.render_to_string(partial: "dependencies/dependencies", formats: [:html], locals: local_var)
  end
end
