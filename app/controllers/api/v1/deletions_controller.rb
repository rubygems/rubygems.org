class Api::V1::DeletionsController < Api::BaseController
  skip_before_action :verify_authenticity_token, only: [:create, :destroy]

  before_action :authenticate_with_api_key, only: [:create, :destroy]
  before_action :verify_authenticated_user, only: [:create, :destroy]
  before_action :find_rubygem_by_name,      only: [:create, :destroy]
  before_action :validate_gem_and_version,  only: [:create]

  def create
    @deletion = current_user.deletions.build(version: @version)
    if @deletion.save
      StatsD.increment 'yank.success'
      render text: "Successfully deleted gem: #{@version.to_title}"
    else
      StatsD.increment 'yank.failure'
      render text: @deletion.errors.full_messages.to_sentence,
             status: :unprocessable_entity
    end
  end

  def destroy
    render text: "Unyanking of gems is no longer supported.",
           status: :gone
  end
end
