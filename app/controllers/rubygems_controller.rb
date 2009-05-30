class RubygemsController < ApplicationController

  def index
    @gems = Rubygem.all
  end

  def show
    @gem = Rubygem.find_by_name(params[:id])
    @current_version = @gem.versions.first
  end
end
