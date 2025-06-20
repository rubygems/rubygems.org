class OrganizationsController < ApplicationController
  before_action :redirect_to_signin, only: :index, unless: :signed_in?
  before_action :redirect_to_new_mfa, only: :index, if: :mfa_required_not_yet_enabled?
  before_action :redirect_to_settings_strong_mfa_required, only: :index, if: :mfa_required_weak_level_enabled?

  before_action :find_organization, only: %i[show edit update]

  layout "subject"

  # GET /organizations
  def index
    @memberships = current_user.memberships.includes(:organization)
  end

  # GET /organizations/1
  def show
    @latest_events = [] # @organization.latest_events
    @gems = @organization
      .rubygems
      .with_versions
      .by_downloads
      .preload(:most_recent_version, :gem_download)
      .load_async
    @gems_count = @organization.rubygems.with_versions.count
    @memberships = @organization.memberships.includes(:user)
    @memberships_count = @organization.memberships.count
  end

  def edit
    add_breadcrumb t("breadcrumbs.org_name", name: @organization.handle), organization_path(@organization)
    add_breadcrumb t("breadcrumbs.settings")

    authorize @organization
  end

  def update
    authorize @organization

    if @organization.update(organization_params)
      redirect_to organization_path(@organization)
    else
      render :edit
    end
  end

  private

  def find_organization
    @organization = Organization.find_by_handle!(params[:id])
  end

  def organization_params
    params.expect(organization: %i[name])
  end
end
