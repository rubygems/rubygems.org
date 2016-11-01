class Api::V1::AdvisoriesController < Api::BaseController
  skip_before_action :verify_authenticity_token, only: [:create]

  before_action :authenticate_with_api_key, only: [:create]
  before_action :verify_authenticated_user, only: [:create]
  before_action :find_rubygem_by_name,      only: [:create]
  before_action :validate_gem_and_version,  only: [:create]

  def create
    @advisory = current_user.advisories.new(version: @version, message: params[:message])
    if @advisory.save
      StatsD.increment 'advisory.success'
      render text: "Successfully marked gem: #{@version.to_title} as vulnerable."
    else
      StatsD.increment 'advisory.failure'
      render text: @advisory.errors.full_messages.to_sentence,
             status: :unprocessable_entity
    end
  end
end
