class Api::V1::DeletionsController < Api::BaseController
  skip_before_action :verify_authenticity_token, only: %i[create destroy]

  before_action :authenticate_with_api_key, only: %i[create destroy]
  before_action :verify_authenticated_user, only: %i[create destroy]
  before_action :find_rubygem_by_name,      only: %i[create destroy]
  before_action :validate_rubygem, only: %i[create]
  before_action :find_version, only: %i[create]

  def create
    @deletion = @api_user.deletions.build(version: @version)
    if @deletion.save
      StatsD.increment 'yank.success'
      render plain: "Successfully deleted gem: #{@version.to_title}"
    else
      StatsD.increment 'yank.failure'
      render plain: @deletion.errors.full_messages.to_sentence,
             status: :unprocessable_entity
    end
  end

  def destroy
    render plain: "Unyanking of gems is no longer supported.",
           status: :gone
  end
end
