class Api::V1::ActivitiesController < Api::BaseController

  def latest
    @rubygems = Rubygem.latest(50)
    render_rubygems
  end

  def just_updated
    @rubygems = Version.just_updated(50).map(&:rubygem)
    render_rubygems
  end

  private

  def render_rubygems
    respond_to do |format|
      format.json { render json: @rubygems }
      format.yaml { render yaml: @rubygems }
    end
  end
end
