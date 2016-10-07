class Api::V1::VersionsController < Api::BaseController
  before_action :find_rubygem, only: :show

  def show
    return unless stale?(@rubygem)

    expires_in 0, public: true
    fastly_expires_in 60

    if @rubygem.public_versions.count.nonzero?
      respond_to do |format|
        format.json { render json: @rubygem.public_versions }
        format.yaml { render yaml: @rubygem.public_versions }
      end
    else
      render text: t(:this_rubygem_could_not_be_found), status: :not_found
    end
  end

  def latest
    rubygem = Rubygem.find_by_name(params[:id])
    version = nil
    if rubygem && rubygem.public_versions.indexed.count.nonzero?
      version = rubygem.versions.most_recent
    end
    number = version.number if version
    render json: { "version" => number || "unknown" }, callback: params['callback']
  end

  def reverse_dependencies
    names = Version.reverse_dependencies(params[:id]).pluck(:full_name)
    respond_to do |format|
      format.json { render json: names }
      format.yaml { render yaml: names }
    end
  end
end
