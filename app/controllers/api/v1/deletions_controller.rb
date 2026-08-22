# frozen_string_literal: true

class Api::V1::DeletionsController < Api::BaseController
  before_action :authenticate_with_api_key
  before_action :verify_user_api_key
  before_action :find_rubygem_by_name
  before_action :verify_api_key_gem_scope
  before_action :validate_ruby_abi
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
             status: :unprocessable_content
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
        version = params.expect(:version)
        platform = params.permit(:platform).fetch(:platform, nil)
        ruby_abi = params.permit(:ruby_abi).fetch(:ruby_abi, nil).presence

        @version = @rubygem.find_version!(number: version, platform: platform, ruby_abi: ruby_abi)
      rescue ActiveRecord::RecordNotFound
        details = "#{" (#{platform})" if platform.present?}#{" (Ruby ABI #{ruby_abi})" if ruby_abi.present?}"
        render plain: response_with_mfa_warning("The version #{version}#{details} does not exist."),
               status: :not_found
      end
    end
  end

  def validate_ruby_abi
    ruby_abi = params.permit(:ruby_abi).fetch(:ruby_abi, nil).presence
    return unless ruby_abi

    if !ruby_abi.match?(/\A\d+\.\d+\z/)
      render plain: response_with_mfa_warning("The ruby_abi param must be in the format X.Y (e.g., 3.2)."),
             status: :bad_request
    elsif params.permit(:platform).fetch(:platform, nil).blank?
      render plain: response_with_mfa_warning("The platform param is required when ruby_abi is specified."),
             status: :bad_request
    end
  end
end
