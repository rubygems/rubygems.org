class Api::V1::ProfilesController < Api::BaseController
  respond_to :yaml, :xml, :json, :only => [:show]

  def show
    respond_with User.find_by_slug!(params[:id]), :yamlish => true
  end
end
