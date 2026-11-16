# frozen_string_literal: true

class Organizations::DomainsController < Organizations::BaseController
  before_action :authorize_manage_domains

  def create
    @domain_input = domain_params[:domain]
    @new_domain = OrganizationDomain.add(organization: @organization, domain: @domain_input)

    if @new_domain.persisted?
      redirect_to edit_organization_path(@organization), notice: t(".added", domain: @new_domain.domain)
    else
      add_edit_breadcrumbs
      set_domain_settings
      render "organizations/edit", status: :unprocessable_content
    end
  end

  def verify
    domain = find_domain

    # Marks the domain as checking and enqueues the background check. The flag
    # is only set when no check is already queued, so repeated clicks enqueue once.
    OrganizationDomain.transaction do
      queued = OrganizationDomain.where(id: domain.id, check_queued_at: nil).update_all(check_queued_at: Time.current)
      OrganizationDomainVerificationJob.perform_later(domain.id) if queued == 1
    end

    redirect_to edit_organization_path(@organization), notice: t("organizations.domains.queued", domain: domain.domain)
  end

  def destroy
    domain = find_domain
    domain.remove!(actor: current_user)

    redirect_to edit_organization_path(@organization), notice: t(".removed", domain: domain.domain)
  end

  private

  def authorize_manage_domains
    authorize @organization, :manage_domains?
  end

  def find_domain
    @organization.domains.find(params.expect(:id))
  end

  def domain_params
    params.expect(organization_domain: [:domain])
  end

  def add_edit_breadcrumbs
    add_breadcrumb t("breadcrumbs.org_name", name: @organization.handle), organization_path(@organization)
    add_breadcrumb t("breadcrumbs.settings")
  end
end
