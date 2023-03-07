class Api::V1::HookRelayController < Api::BaseController
  before_action :set_hook_relay_report_params
  before_action :authenticate_hook_relay_report

  rescue_from ActiveSupport::SecureCompareRotator::InvalidMatch, with: :render_not_found

  def report
    Rails.logger.info({ hook_relay_report: @hook_relay_report_params }.to_json)

    stream = @hook_relay_report_params.require(:stream).slice(/:webhook_id-(\d+)\z/, 1)&.to_i
    hook = WebHook.find(stream)
    hook.increment! :failure_count if @hook_relay_report_params.require(:status) == "failure"

    respond_to do |format|
      format.json { render json: {} }
    end
  end

  private

  def set_hook_relay_report_params
    @hook_relay_report_params = params.permit(
      :attempts, :account_id, :hook_id, :id, :max_attempts,
      :status, :stream, :failure_reason, :completed_at,
      :created_at, request: [:target_url]
    )
  end

  def authenticate_hook_relay_report
    account_id, hook_id = @hook_relay_report_params.require(%i[account_id hook_id])

    ActiveSupport::SecureCompareRotator.new(ENV.fetch("HOOK_RELAY_ACCOUNT_ID", "")).secure_compare!(account_id)
    ActiveSupport::SecureCompareRotator.new(ENV.fetch("HOOK_RELAY_HOOK_ID", "")).secure_compare!(hook_id)
  end
end
