class VersionsController < ApplicationController
  before_filter :find_rubygem

  def index
    @versions = @rubygem.versions
  end

  protected

  def find_rubygem
    @rubygem = Rubygem.find_by_name(params[:rubygem_id])
  end

  #def show
  #  @version = Version.find(params[:id])
  #end

end
