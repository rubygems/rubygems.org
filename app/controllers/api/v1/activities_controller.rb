class Api::V1::ActivitiesController < Api::BaseController
  respond_to :json, :xml, :yaml, :on => [:latest, :just_updated]

  def latest
    @rubygems = Rubygem.latest(50)
    respond_with(@rubygems, :yamlish => true)
  end

  def just_updated
    updated_gems = versions_to_gem_hash(Version.just_updated(50))
    respond_with(updated_gems, :yamlish => true)
  end


end
