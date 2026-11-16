# frozen_string_literal: true

class Organizations::TeamsController < Organizations::BaseController
  before_action :render_not_found, unless: :organization_teams_enabled?

  rescue_from Pundit::NotAuthorizedError, with: :render_not_found

  def index
    authorize @organization, :list_teams?

    @teams = @organization.organization_teams.order(:name).load
    @team_size = @teams.size
  end

  def show
    @team = @organization.organization_teams.find_by_case_insensitive_handle!(params.expect(:id))
    authorize @team, :show?
  end

  def new
    authorize @organization, :create_team?
    @team = @organization.organization_teams.build
  end

  def create
    authorize @organization, :create_team?
    @team = @organization.organization_teams.build(team_params)

    if @team.save_with_creation_event(actor: current_user)
      redirect_to organization_teams_path(@organization), notice: t(".team_created")
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def organization_teams_enabled?
    FeatureFlag.enabled?(FeatureFlag::ORGANIZATION_TEAMS, @organization)
  end

  def team_params
    params.expect(organization_team: %i[name handle])
  end
end
