# frozen_string_literal: true

class Api::V2::ContentsController < Api::BaseController
  before_action :find_rubygem_by_name, only: [:index]
  before_action :validate_ruby_abi, only: [:index]

  def index
    return unless stale?(@rubygem)
    cache_expiry_headers
    set_surrogate_key "gem/#{@rubygem.name}"

    find_version
    return unless @version

    checksums_file = @version.manifest.checksums_file
    return render plain: "Content is unavailable for this version.", status: :not_found unless checksums_file

    respond_to do |format|
      format.json { render json: checksums_payload(checksums_file) }
      format.yaml { render yaml: checksums_payload(checksums_file) }
      format.sha256 { render plain: checksums_file }
    end
  end

  protected

  def find_version
    version_params = params.permit(:version_number, :platform, :ruby_abi)
    ruby_abi = version_params[:ruby_abi].presence

    @version = @rubygem.find_public_version(version_params[:version_number], version_params[:platform], ruby_abi)
    render plain: "This version could not be found.", status: :not_found unless @version
  end

  def checksums_payload(checksums_file)
    ShasumFormat.parse(checksums_file).transform_values do |checksum|
      { VersionManifest::DEFAULT_DIGEST => checksum }
    end
  end

  private

  def validate_ruby_abi
    ruby_abi = params.permit(:ruby_abi).fetch(:ruby_abi, nil).presence
    return unless ruby_abi

    if !ruby_abi.match?(/\A\d+\.\d+\z/)
      render plain: "The ruby_abi param must be in the format X.Y (e.g., 3.2).", status: :bad_request
    elsif params[:platform].blank?
      render plain: "The platform param is required when ruby_abi is specified.", status: :bad_request
    end
  end
end
