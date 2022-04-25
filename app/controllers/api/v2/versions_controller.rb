class Api::V2::VersionsController < Api::BaseController
  before_action :find_rubygem_by_name, only: [:show]

  def show
    return unless stale?(@rubygem)

    fields = (params[:fields] || "").split(",").compact_blank
    version = @rubygem.public_version_payload(params[:number], platform: params[:platform], fields: fields)
    if version
      respond_to do |format|
        format.json { render json: version }
        format.yaml { render yaml: version }
      end
    else
      render plain: "This version could not be found.", status: :not_found
    end
  end
end
