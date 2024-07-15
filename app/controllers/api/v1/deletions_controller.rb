class Api::V1::DeletionsController < Api::BaseController
  before_action :authenticate_with_api_key
  before_action :verify_user_api_key
  before_action :find_rubygem_by_name
  before_action :verify_api_key_gem_scope
  before_action :validate_gem_and_version
  before_action :verify_with_otp

  def create
    authorize @rubygem, :yank? # TODO: change to @version
    @deletion = @api_key.user.deletions.build(version: @version)
    if @deletion.save
      StatsD.increment "yank.success"
      render plain: response_with_mfa_warning("Successfully deleted gem: #{@version.to_title}")
    elsif @deletion.ineligible?
      StatsD.increment "yank.forbidden"
      @deletion.record_yank_forbidden_event!
      contact = "Please contact RubyGems support (support@rubygems.org) to request deletion of this version " \
                "if it represents a legal or security risk."
      message = "#{@deletion.ineligible_reason} #{contact}"
      render plain: response_with_mfa_warning(message), status: :forbidden
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
      render_forbidden response_with_mfa_warning("You do not have permission to delete this gem.")
    else
      begin
        version = params.permit(:version).require(:version)
        platform = params.permit(:platform).fetch(:platform, nil)
        @version = @rubygem.find_version!(number: version, platform: platform)
      rescue ActiveRecord::RecordNotFound
        render plain: response_with_mfa_warning("The version #{version}#{" (#{platform})" if platform.present?} does not exist."),
               status: :not_found
      end
    end
  end
end
