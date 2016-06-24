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

  private

  def validate_gem_and_version
    if !@rubygem.hosted?
      render plain: t(:this_rubygem_could_not_be_found),
             status: :not_found
    elsif !@rubygem.owned_by?(current_user)
      render plain: "You do not have permission to delete this gem.",
             status: :forbidden
    else
      begin
        slug = if params[:platform].blank?
                 params[:version]
               else
                 "#{params[:version]}-#{params[:platform]}"
               end
        @version = Version.find_from_slug!(@rubygem, slug)
      rescue ActiveRecord::RecordNotFound
        render plain: "The version #{params[:version]} does not exist.",
               status: :not_found
      end
    end
  end
end
