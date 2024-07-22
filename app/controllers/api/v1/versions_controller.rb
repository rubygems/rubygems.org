class Api::V1::VersionsController < Api::BaseController
  before_action :find_rubygem, only: :show

  def show
    return unless stale?(@rubygem)

    cache_expiry_headers
    set_surrogate_key "gem/#{@rubygem.name}"

    versions = @rubygem.public_versions.includes(:gem_download)
    if versions.present?
      respond_to do |format|
        format.json { render json: versions }
        format.yaml { render yaml: versions }
      end
    else
      render plain: t(:this_rubygem_could_not_be_found), status: :not_found
    end
  end

  def latest
    rubygem = Rubygem.find_by_name(params[:id])

    cache_expiry_headers
    set_surrogate_key "gem/#{params[:id]}"

    version = nil
    version = rubygem.most_recent_version if rubygem&.public_versions.present?
    number = version.number if version
    render json: { "version" => number || "unknown" }, callback: params["callback"]
  end

  def reverse_dependencies
    cache_expiry_headers(fastly_expiry: 30)

    names = Version.reverse_dependencies(params[:id]).pluck(:full_name)
    respond_to do |format|
      format.json { render json: names }
      format.yaml { render yaml: names }
    end
  end
end
