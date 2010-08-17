class Api::V1::DependenciesController < ApplicationController
  def index
    render :text => Marshal.dump(Dependency.for(params[:gems]))
  end
end
