class RubygemsController < ApplicationController

  def index
    @gems = Rubygem.by_name(:asc)
  end

  def show
    @gem = Rubygem.find(params[:id])
    @current_version = @gem.versions.first
  end
end
