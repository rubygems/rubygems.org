class Api::V1::AdvisoriesController < Api::BaseController
  skip_before_action :verify_authenticity_token, only: [:create]

  before_action :authenticate_with_api_key, only: [:create]
  before_action :verify_authenticated_user, only: [:create]
  before_action :find_rubygem_by_name,      only: [:create]
  before_action :validate_rubygem, only: [:create]
  before_action :find_version, only: [:create]

  def create
    @advisory = @version.advisories.new(description: params[:description], title: params[:title], url: params[:url], cve: params[:cve])
    if @advisory.save
      StatsD.increment 'advisory.success'
      render plain: "Successfully recorded advisory for gem: #{@version.to_title}"
    else
      StatsD.increment 'advisory.failure'
      render plain: "Failed to add advisory: " + @advisory.errors.full_messages.to_sentence,
             status: :unprocessable_entity
    end
  end
end
