class Api::V1::DeletionsController < Api::BaseController
  before_action :authenticate_with_api_key
  before_action :find_rubygem_by_name
  before_action :verify_api_key_gem_scope
  before_action :validate_gem_and_version
  before_action :verify_with_otp
  before_action :render_api_key_forbidden, if: :api_key_unauthorized?
  before_action :verify_mfa_requirement

  def create
    @deletion = @api_key.user.deletions.build(version: @version)
    if @deletion.save
      StatsD.increment "yank.success"
      enqueue_web_hook_jobs(@version)
      render plain: "Successfully deleted gem: #{@version.to_title}"
    else
      StatsD.increment "yank.failure"
      render plain: @deletion.errors.full_messages.to_sentence,
             status: :unprocessable_entity
    end
  end

  private

  def validate_gem_and_version
    if !@rubygem.hosted?
      render plain: t(:this_rubygem_could_not_be_found),
             status: :not_found
    elsif !@rubygem.owned_by?(@api_key.user)
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

  def api_key_unauthorized?
    !@api_key.can_yank_rubygem?
  end
end
