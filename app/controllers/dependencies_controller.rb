class DependenciesController < ApplicationController
  include LatestVersion
  include RequirementsVersion

  def show
    latest_version_by_slug
    @dependencies = Hash.new { |h, k| h[k] = [] }

    @latest_version.dependencies.each do |dependency|
      gem_name = dependency.rubygem.name
      gem_details = [gem_name, dep_resolver(
        gem_name,
        dependency["requirements"],
        dependency.rubygem.public_versions.pluck(:number)
      ), dependency.requirements]
      @dependencies[dependency.scope] << gem_details
    end
  end
end
