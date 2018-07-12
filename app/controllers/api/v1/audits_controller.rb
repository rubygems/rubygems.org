class Api::V1::AuditsController < Api::BaseController
  skip_before_action :verify_authenticity_token, only: [:check]

  before_action :authenticate_with_api_key, only: [:check]
  before_action :verify_authenticated_user, only: [:check]
  before_action :find_rubygem_by_name,      only: [:check]
  before_action :validate_gem_and_version,  only: [:check]

  def check
    response = {}
    if @version
      response = check_version(@version)
    else
      @versions.compact.each { |version| response[version] = check_version(version) }
    end

    respond_to do |format|
      format.json { render json: response }
    end
  end

  private

  def check_version(version)
    if version.vulnerable
      params[:ignored_cves] = [] if params[:ignored_cves].blank?
      Advisory.find_vulnerability(version, params[:ignored_cves])
    else
      "This version does not contain any vulnerabilities"
    end
  end
end
