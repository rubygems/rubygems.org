class OwnershipRequestsController < ApplicationController
  before_action :find_rubygem
  before_action :find_ownership_request, only: :update
  before_action :redirect_to_signin, unless: :signed_in?
  before_action :redirect_to_new_mfa, if: :mfa_required_not_yet_enabled?
  before_action :redirect_to_settings_strong_mfa_required, if: :mfa_required_weak_level_enabled?

  def create
    render_forbidden && return unless current_user.can_request_ownership?(@rubygem)

    @ownership_request = @rubygem.ownership_requests.new(ownership_call: @rubygem.ownership_call, user: current_user, note: params[:note])
    if @ownership_request.save
      redirect_to rubygem_adoptions_path(@rubygem), notice: t("ownership_requests.create.success_notice")
    else
      redirect_to rubygem_adoptions_path(@rubygem), alert: @ownership_request.errors.full_messages.to_sentence
    end
  end

  def update
    if status_params == "close" && @ownership_request.close(current_user)
      notify_request_closed
      redirect_to rubygem_adoptions_path(@rubygem), notice: t("ownership_requests.update.closed_notice")
    elsif status_params == "approve" && @ownership_request.approve(current_user)
      notify_request_approved
      redirect_to rubygem_adoptions_path(@rubygem), notice: t("ownership_requests.update.approved_notice", name: current_user.display_id)
    else
      redirect_to rubygem_adoptions_path(@rubygem), alert: t("try_again")
    end
  end

  def close_all
    render_forbidden && return unless owner?

    if @rubygem.ownership_requests.close_all
      redirect_to rubygem_adoptions_path(@rubygem), notice: t("ownership_requests.close.success_notice", gem: @rubygem.name)
    else
      redirect_to rubygem_adoptions_path(@rubygem), alert: t("try_again")
    end
  end

  private

  def find_ownership_request
    @ownership_request = OwnershipRequest.find(params[:id])
  end

  def notify_request_closed
    OwnersMailer.delay.ownership_request_closed(@ownership_request.id) unless @ownership_request.user == current_user
  end

  def notify_request_approved
    @rubygem.ownership_notifiable_owners.each do |notified_user|
      OwnersMailer.delay.owner_added(notified_user.id,
        @ownership_request.user_id,
        current_user.id,
        @ownership_request.rubygem_id)
    end

    OwnersMailer.delay.ownership_request_approved(@ownership_request.id)
  end

  def status_params
    params.require(:status)
  end
end
