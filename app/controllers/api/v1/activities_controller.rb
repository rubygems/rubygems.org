class Api::V1::ActivitiesController < Api::BaseController
  def latest
    rubygems = Rubygem.includes(:linkset, :gem_download, latest_version: %i[dependencies gem_download])
      .order(created_at: :desc)
      .where(indexed: true)
      .limit(50)
      .map { |rubygem| rubygem.payload(rubygem.latest_version) }
    render_rubygems(rubygems)
  end

  def just_updated
    rubygems = Version.includes(:dependencies, :gem_download, rubygem: %i[linkset gem_download])
      .just_updated(50)
      .map { |version| version.rubygem.payload(version) }
    render_rubygems(rubygems)
  end

  private

  def render_rubygems(rubygems)
    set_surrogate_key "api/v1/activities"
    cache_expiry_headers

    respond_to do |format|
      format.json { render json: rubygems }
      format.yaml { render yaml: rubygems }
    end
  end
end
