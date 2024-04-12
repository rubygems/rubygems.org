class Api::V1::HookRelayController < Api::BaseController
  before_action :authenticate_hook_relay_report

  rescue_from ActiveSupport::SecureCompareRotator::InvalidMatch, with: :render_not_found

  def report
    HookRelayReportJob.perform_later(hook_relay_report_params)

    respond_to do |format|
      format.json { render json: {} }
    end
  end

  private

  def hook_relay_report_params
    params.permit(
      :attempts, :id, :max_attempts,
      :status, :stream, :failure_reason, :completed_at,
      :created_at, request: [:target_url]
    )
  end

  def authenticate_hook_relay_report
    account_id, hook_id = params_fetch(%i[account_id hook_id])

    ActiveSupport::SecureCompareRotator.new(ENV.fetch("HOOK_RELAY_ACCOUNT_ID", "")).secure_compare!(account_id)
    ActiveSupport::SecureCompareRotator.new(ENV.fetch("HOOK_RELAY_HOOK_ID", "")).secure_compare!(hook_id)
  end
end
