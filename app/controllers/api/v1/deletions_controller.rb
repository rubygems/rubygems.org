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
      render plain: response_with_mfa_warning("Successfully deleted gem: #{@version.to_title}")
    else
      StatsD.increment "yank.failure"
      render plain: response_with_mfa_warning(@deletion.errors.full_messages.to_sentence),
             status: :unprocessable_entity
    end
  end

  private

  def validate_gem_and_version
    if !@rubygem.hosted?
      render plain: response_with_mfa_warning(t(:this_rubygem_could_not_be_found)),
             status: :not_found
    elsif !@rubygem.owned_by?(@api_key.user)
      render plain: response_with_mfa_warning("You do not have permission to delete this gem."),
             status: :forbidden
    else
      begin
        version = params.require(:version)
        platform = params.permit(:platform).fetch(:platform, nil)
        @version = @rubygem.find_version!(number: version, platform: platform)
      rescue ActiveRecord::RecordNotFound
        render plain: response_with_mfa_warning("The version #{version}#{" (#{platform})" if platform.present?} does not exist."),
               status: :not_found
      end
    end
  end

  def api_key_unauthorized?
    !@api_key.can_yank_rubygem?
  end
end
