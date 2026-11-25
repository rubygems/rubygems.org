# frozen_string_literal: true

class Organizations::Teams::MembersController < Organizations::BaseController
  before_action :render_not_found, unless: :organization_teams_enabled?
  before_action :find_team

  rescue_from Pundit::NotAuthorizedError, with: :render_not_found

  def create
    authorize @team, :add_member?
    memberships = @team.addable_memberships.where(id: params.permit(membership_ids: [])[:membership_ids])

    return redirect_to organization_team_path(@organization, @team), alert: t(".none_selected") if memberships.none?

    added = @team.add_members!(memberships, actor: current_user)
    redirect_to organization_team_path(@organization, @team), notice: t(".added", count: added.size)
  end

  def destroy
    authorize @team, :remove_member?
    membership = @team.memberships.includes(:user).find(params.expect(:id))

    @team.remove_member!(membership, actor: current_user)
    redirect_to organization_team_path(@organization, @team), notice: t(".removed", handle: membership.user.handle)
  end

  private

  def organization_teams_enabled?
    FeatureFlag.enabled?(FeatureFlag::ORGANIZATION_TEAMS, @organization)
  end

  def find_team
    @team = @organization.organization_teams.find_by_case_insensitive_handle!(params.expect(:team_id))
  end
end
