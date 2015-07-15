class Api::V2::VersionsController < Api::BaseController
  before_action :find_rubygem_by_name, only: [:show]

  def show
    return unless stale?(@rubygem)

    version = @rubygem.public_versions.find_by(number: params[:number])
    if version
      respond_to do |format|
        format.json { render json: version }
        format.yaml { render yaml: version }
      end
    else
      render text: "This version could not be found.", status: 404
    end
  end
end
