class Api::V1::VersionsController < Api::BaseController
  # Returns a JSON array of gem version details like the below:
  # [
  #     {
  #        "latest" : false,
  #        "number" : "1.0.0",
  #        "position" : 1,
  #        "built_at" : "2011-02-19T04:29:19Z",
  #        "indexed" : true,
  #        "created_at" : "2011-02-20T04:29:19Z",
  #        "summary" : null,
  #        "downloads_count" : 0,
  #        "platform" : "ruby",
  #        "id" : 547,
  #        "authors" : "Joe User",
  #        "full_name" : "RubyGem1-1.0.0",
  #        "description" : "Some awesome gem",
  #        "prerelease" : false,
  #        "rubyforge_project" : null,
  #        "updated_at" : "2011-02-20T04:29:19Z",
  #        "rubygem_id" : 573
  #     },
  #     {
  #        "latest" : true,
  #        "number" : "2.0.0",
  #        "position" : 0,
  #        "built_at" : "2011-02-19T04:29:19Z",
  #        "indexed" : true,
  #        "created_at" : "2011-02-20T04:29:19Z",
  #        "summary" : null,
  #        "downloads_count" : 0,
  #        "platform" : "ruby",
  #        "id" : 548,
  #        "authors" : "Joe User",
  #        "full_name" : "RubyGem1-2.0.0",
  #        "description" : "Some awesome gem",
  #        "prerelease" : false,
  #        "rubyforge_project" : null,
  #        "updated_at" : "2011-02-20T04:29:19Z",
  #        "rubygem_id" : 573
  #     }
  # ]
  def show
    gem_name = params[:id].try(:chomp, ".json")
    if rubygem = Rubygem.find_by_name(gem_name)
      render :json => rubygem.versions
    else
      render :text => "This rubygem could not be found.", :status => 404
    end
  end
end
