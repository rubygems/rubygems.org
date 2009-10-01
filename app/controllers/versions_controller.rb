class VersionsController < ApplicationController
  before_filter :find_rubygem

  def index
    @versions = @rubygem.versions
  end

  def show
    @latest_version = @rubygem.versions.find_by_number(params[:id])
    render "rubygems/show"
  end

  protected

  def find_rubygem
    @rubygem = Rubygem.find_by_name(params[:rubygem_id])
  end

end
