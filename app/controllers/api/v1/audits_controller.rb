class Api::V1::AuditsController < Api::BaseController
  skip_before_action :verify_authenticity_token, only: [:check]

  before_action :authenticate_with_api_key, only: [:check]
  before_action :verify_authenticated_user, only: [:check]
  before_action :find_rubygem_by_name,      only: [:check]
  before_action :validate_gem_and_version,  only: [:check]

  def check
  	@response = []
  	if @version
      render plain: check_version(@version)  
    else
       @versions.compact.each { |version| @response << check_version(version) }
       render plain: @response
   	end
  end

  private

  def check_version(version)
  	is_vuln = version.vulnerable
  	if is_vuln
  	  "#{version.number}: This version contains vulnerabilities"
  	else
  	  "#{version.number}: This version does not contain any vulnerabilities"
  	end
  end
end
