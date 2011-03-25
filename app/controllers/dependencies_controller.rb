class DependenciesController < ApplicationController
  before_filter :find_gem,      :only => :show

  def show
    @version = params[:version_id] ? Version.find_from_slug!(@rubygem.id, params[:version_id]) : @rubygem.versions.most_recent
  end

  protected

  def find_rubygem
    @rubygem = Rubygem.find_by_name(params[:rubygem_id])
  end
end
