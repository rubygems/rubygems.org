class Api::V1::ActivitiesController < Api::BaseController
  respond_to :json, :xml, :yaml, :on => [:latest, :just_updated]

  def latest
    @rubygems = Rubygem.latest(50)
    respond_with(@rubygems, :yamlish => true)
  end

  def just_updated
    @rubygems = Version.just_updated(50).map(&:rubygem)
    respond_with(@rubygems, :yamlish => true)
  end

end
