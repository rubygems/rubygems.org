# frozen_string_literal: true

class Api::V2::VersionsController < Api::BaseController
  before_action :find_rubygem_by_name, only: [:show]
  before_action :validate_ruby_abi, only: [:show]

  def show
    return unless stale?(@rubygem)
    cache_expiry_headers
    set_surrogate_key "gem/#{@rubygem.name}"

    ruby_abi = version_params[:ruby_abi].presence

    version = @rubygem.public_version_payload(version_params[:number], version_params[:platform], ruby_abi)
    if version
      respond_to do |format|
        format.json { render json: version }
        format.yaml { render yaml: version }
      end
    else
      render plain: "This version could not be found.", status: :not_found
    end
  end

  protected

  def version_params
    params.permit(:platform, :number, :ruby_abi)
  end

  private

  def validate_ruby_abi
    ruby_abi = version_params[:ruby_abi].presence
    return unless ruby_abi

    if !ruby_abi.match?(/\A\d+\.\d+\z/)
      render plain: "The ruby_abi param must be in the format X.Y (e.g., 3.2).", status: :bad_request
    elsif version_params[:platform].blank?
      render plain: "The platform param is required when ruby_abi is specified.", status: :bad_request
    end
  end
end
