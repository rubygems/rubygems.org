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
    contact_admin = "Please contact RubyGems support to request deletion of this version if it represents a legal or security risk."
    if @version.created_at.before? 30.days.ago
      render plain: response_with_mfa_warning("Versions published more than 30 days ago cannot be deleted. #{contact_admin}"),
             status: :forbidden
    elsif @version.downloads_count > 100_000
      render plain: response_with_mfa_warning("Versions with more than 100,000 downloads cannot be deleted. #{contact_admin}"),
             status: :forbidden
    end
  end
end
