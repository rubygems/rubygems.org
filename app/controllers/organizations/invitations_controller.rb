# frozen_string_literal: true

class Organizations::InvitationsController < Organizations::BaseController
  layout "application"

  before_action :find_membership
  before_action :redirect_expired_invitation, only: %i[show update], if: -> { @membership.invitation_expired? }

  def show
  end

  def update
    if @membership.confirm!
      redirect_to organization_path(@organization), notice: "You have successfully joined the #{@organization.handle} organization."
    else
      redirect_expired_invitation
    end
  end

  def destroy
    @membership.destroy!
    redirect_to dashboard_path, notice: t(".declined", organization: @organization.handle)
  end

  private

  def find_membership
    @membership = Membership.find_by!(organization: @organization, user: current_user, confirmed_at: nil)
  end

  def redirect_expired_invitation
    redirect_to organization_path(@organization), alert: t("organizations.invitations.expired")
  end
end
