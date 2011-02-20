class Api::V1::VersionsController < Api::BaseController

  def show
    gem_name = params[:id].try(:chomp, ".json")
    if rubygem = Rubygem.find_by_name(gem_name)
      render :json => rubygem.versions
    else
      render :text => "This rubygem could not be found.", :status => 404
    end
  end
end
