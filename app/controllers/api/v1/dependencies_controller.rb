class Api::V1::DependenciesController < Api::BaseController
  before_action :set_gems, only: :index

  def index
    dependencies = dependencies_for(@gems)
    respond_to do |format|
      format.json { render json: dependencies }
      format.any { render text: Marshal.dump(dependencies), content_type: "application/octet-stream" }
    end
  end

  private

  def set_gems
    @gems = params[:gems].split(',')
    return unless @gems.size > 200
    respond_to do |format|
      format.json do
        render json: {
          error: "Too many gems (use --full-index instead)",
          code: 422
        }, status: 422
      end
      format.any { render text: "Too many gems (use --full-index instead)", status: 422 }
    end
  end

  def dependencies_result(names)
    group_by_columns =
      "rubygems.name, number, platform, sha256, ruby_version, versions.created_at"
    dep_req_agg =
      "string_agg(dependencies.requirements, '@' order by rubygems_dependencies.name)"
    dep_name_agg =
      "string_agg(rubygems_dependencies.name, ',' order by rubygems_dependencies.name) as dep_name"

    Rubygem.includes(versions: { dependencies: :rubygem })
      .where("rubygems.name IN (?) and indexed = true and (scope = 'runtime' or scope is null)", names)
      .group(group_by_columns)
      .order("rubygems.name, versions.created_at, number, platform, dep_name")
      .pluck("#{group_by_columns}, #{dep_req_agg}, #{dep_name_agg}")
  end

  def dependencies_for(names)
    dependencies_result(names).map do |r|
      name, version, platform, checksum, ruby_version, created_at, dep_reqs, dep_names = r
      rubygems_version = ">= 0" # TODO: get this from the DB
      deps = if dep_reqs
               dep_reqs = dep_reqs.split('@')
               dep_names = dep_names.split(',')
               fail 'BUG: different size of reqs and dep_names.' unless dep_reqs.size == dep_names.size
               dep_names.zip(dep_reqs)
             else
               []
             end

      {
        name: name,
        number: version,
        platform: platform,
        rubygems_version: rubygems_version,
        ruby_version: ruby_version,
        checksum: checksum,
        created_at: created_at,
        dependencies: deps
      }
    end
  end
end
