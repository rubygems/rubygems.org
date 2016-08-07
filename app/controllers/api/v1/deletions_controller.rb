class Api::V1::DeletionsController < Api::BaseController
  skip_before_action :verify_authenticity_token, only: [:create, :destroy]

  before_action :authenticate_with_api_key, only: [:create, :destroy]
  before_action :verify_authenticated_user, only: [:create, :destroy]
  before_action :find_rubygem_by_name,      only: [:create, :destroy]
  before_action :validate_gem_and_version,  only: [:create]

  def create
    if @version.can_yank?
      @deletion = current_user.deletions.build(version: @version)
      if @deletion.save
        StatsD.increment 'yank.success'
        render text: "Successfully deleted gem: #{@version.to_title}"
      else
        StatsD.increment 'yank.failure'
        render text: "The version #{params[:version]} has already been deleted.",
               status: :unprocessable_entity
      end
    else
      StatsD.increment 'yank.failure'
      render text: "This gem version cannot be deleted. Contact RubyGems for further assistance",
             status: :bad_request
    end
  end

  def destroy
    render text: "Unyanking of gems is no longer supported.",
           status: :gone
  end

  private

  def validate_gem_and_version
    if !@rubygem.hosted?
      render text: t(:this_rubygem_could_not_be_found),
             status: :not_found
    elsif !@rubygem.owned_by?(current_user)
      render text: "You do not have permission to delete this gem.",
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
        render text: "The version #{params[:version]} does not exist.",
               status: :not_found
      end
    end
  end
end
