class Api::V2::VersionsController < Api::BaseController
  before_action :find_rubygem_by_name, only: [:show]

  def show
    return unless stale?(@rubygem)
    cache_expiry_headers
    set_surrogate_key "gem/#{@rubygem.name}"

    version = @rubygem.public_version_payload(version_params[:number], version_params[:platform])
    if version
      respond_to do |format|
        format.json { render json: version }
        format.yaml { render yaml: version }
        format.sha256 do
          hashes = @rubygem.version_manifest(version_params[:number], version_params[:platform]).checksums_file
          if hashes
            render plain: hashes
          else
            render plain: "SHA256 format unavailable for this version.", status: :not_found
          end
        end
      end
    else
      render plain: "This version could not be found.", status: :not_found
    end
  end

  protected

  def version_params
    params.permit(:platform, :number)
  end
end
