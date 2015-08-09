class Api::V1::ActivitiesController < Api::BaseController
  def latest
    @rubygems = Rubygem.latest(50)
    render_as @rubygems
  end

  def just_updated
    @rubygems = Version.just_updated(50).map(&:rubygem)
    render_as @rubygems
  end
end
