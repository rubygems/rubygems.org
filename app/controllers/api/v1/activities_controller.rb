class Api::V1::ActivitiesController < Api::BaseController
  def latest
    versions = Version.new_pushed_versions(50)
    render_rubygems(versions)
  end

  def just_updated
    versions = Version.just_updated(50)
    render_rubygems(versions)
  end

  private

  def render_rubygems(versions)
    rubygems = versions.includes(:dependencies, rubygem: %i[linkset gem_download]).map do |version|
      version.rubygem.payload(version)
    end

    respond_to do |format|
      format.json { render json: rubygems }
      format.yaml { render yaml: rubygems }
    end
  end
end
