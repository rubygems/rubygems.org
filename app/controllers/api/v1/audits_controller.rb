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
    elsif @versions
      @versions.compact.each { |version| response = response.merge(check_version(version)) }
    end

    respond_to do |format|
      format.json { render json: response }
    end
  end

  private

  def check_version(version)
    data = {}

    if version.advisories.present?
      params[:ignored_cves] = [] if params[:ignored_cves].blank?
      data[version.to_s] = { vulnerable: true, advisories: fetch_advisory_details(version) }
    else
      data[version.to_s] = { vulnerable: false, advisories: "This version does not contain any advisories" }
    end
    data
  end

  def fetch_advisory_details(version)
    version.advisories.pluck(:title, :description, :url, :cve)
  end
end
