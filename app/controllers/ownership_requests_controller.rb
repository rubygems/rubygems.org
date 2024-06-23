class OwnershipRequestsController < ApplicationController
  before_action :find_rubygem
  before_action :redirect_to_signin, unless: :signed_in?
  before_action :redirect_to_new_mfa, if: :mfa_required_not_yet_enabled?
  before_action :redirect_to_settings_strong_mfa_required, if: :mfa_required_weak_level_enabled?

  rescue_from ActiveRecord::RecordInvalid, with: :redirect_try_again
  rescue_from ActiveRecord::RecordNotSaved, with: :redirect_try_again

  def create
    ownership_request = authorize @rubygem.ownership_requests.new(
      ownership_call: @rubygem.ownership_call,
      user: current_user,
      note: params[:note]
    )
    if ownership_request.save
      redirect_to rubygem_adoptions_path(@rubygem.slug), notice: t(".success_notice")
    else
      redirect_to rubygem_adoptions_path(@rubygem.slug), alert: ownership_request.errors.full_messages.to_sentence
    end
  end

  def update
    @ownership_request = OwnershipRequest.find(params[:id])

    case params.permit(:status).require(:status)
    when "close" then close
    when "approve" then approve
    else redirect_try_again
    end
  end

  def close_all
    authorize(@rubygem, :close_ownership_requests?).ownership_requests.each(&:close!)
    redirect_to rubygem_adoptions_path(@rubygem.slug), notice: t("ownership_requests.close.success_notice", gem: @rubygem.name)
  end

  private

  def approve
    authorize(@ownership_request, :approve?).approve!(current_user)
    redirect_to rubygem_adoptions_path(@rubygem.slug), notice: t(".approved_notice", name: current_user.display_id)
  end

  def close
    authorize(@ownership_request, :close?).close!(current_user)
    redirect_to rubygem_adoptions_path(@rubygem.slug), notice: t(".closed_notice")
  end

  def redirect_try_again(_exception = nil)
    redirect_to rubygem_adoptions_path(@rubygem.slug), alert: t("try_again")
  end
end
