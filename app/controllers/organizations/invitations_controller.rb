# frozen_string_literal: true

class Organizations::InvitationsController < Organizations::BaseController
  layout "application"

  before_action :find_membership
  before_action :redirect_expired_invitation, only: %i[show update], if: -> { @membership.invitation_expired? }

  def show
  end

  def update
    confirmed = with_pending_membership_locked { @membership.confirm! }

    if confirmed
      redirect_to organization_path(@organization), notice: "You have successfully joined the #{@organization.handle} organization."
    else
      redirect_expired_invitation
    end
  end

  def destroy
    with_pending_membership_locked { @membership.destroy! }
    redirect_to dashboard_path, notice: t(".declined", organization: @organization.handle)
  end

  private

  # Accept and decline lock the same row and re-check it, so whichever runs first wins
  # and the other gets a 404 instead of acting on a stale copy.
  def with_pending_membership_locked
    @membership.with_lock do
      raise ActiveRecord::RecordNotFound if @membership.confirmed?

      yield
    end
  end

  def find_membership
    @membership = Membership.find_by!(organization: @organization, user: current_user, confirmed_at: nil)
  end

  def redirect_expired_invitation
    redirect_to organization_path(@organization), alert: t("organizations.invitations.expired")
  end
end
