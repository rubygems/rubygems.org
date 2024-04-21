class Api::V1::DeletionsController < Api::BaseController
  before_action :authenticate_with_api_key
  before_action :verify_user_api_key
  before_action :find_rubygem_by_name
  before_action :verify_api_key_gem_scope
  before_action :validate_gem_and_version
  before_action :verify_with_otp
  before_action :render_api_key_forbidden, if: :api_key_unauthorized?
  before_action :verify_mfa_requirement
  before_action :verify_deletion_eligibility

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
        version = params_fetch(:version)
        platform = params_fetch(:platform, nil)
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

  def verify_deletion_eligibility
    if @version.created_at.before? 30.days.ago
      render_yank_forbidden "Versions published more than 30 days ago cannot be deleted."
    elsif @version.downloads_count > 100_000
      render_yank_forbidden "Versions with more than 100,000 downloads cannot be deleted."
    end
  end

  def render_yank_forbidden(reason)
    @version.rubygem.record_event!(
      Events::RubygemEvent::VERSION_YANK_FORBIDDEN,
      reason: reason,
      number: @version.number,
      platform: @version.platform,
      yanked_by: @api_key.user&.display_handle,
      actor_gid: @api_key.user&.to_gid,
      version_gid: @version.to_gid
    )
    message = "#{reason} Please contact RubyGems support to request deletion of this version if it represents a legal or security risk."
    render plain: response_with_mfa_warning(message), status: :forbidden
  end
end
