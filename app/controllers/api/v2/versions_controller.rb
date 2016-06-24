class Api::V2::VersionsController < Api::BaseController
  before_action :find_rubygem_by_name, only: [:show]

  def show
    return unless stale?(@rubygem)

    version = @rubygem.public_version_payload(params[:number])
    if version
      respond_to do |format|
        format.json { render json: version }
        format.yaml { render yaml: version }
      end
    else
      render plain: "This version could not be found.", status: 404
    end
  end
end
