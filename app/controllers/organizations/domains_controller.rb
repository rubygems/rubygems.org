# frozen_string_literal: true

class Organizations::DomainsController < Organizations::BaseController
  before_action :authorize_manage_domains

  def create
    @domain_input = domain_params[:domain]
    @new_domain = OrganizationDomain.new(organization: @organization, domain: @domain_input)

    if @new_domain.save
      redirect_to edit_organization_path(@organization), notice: t(".added", domain: @new_domain.domain)
    else
      add_edit_breadcrumbs
      set_domain_settings
      render "organizations/edit", status: :unprocessable_content
    end
  end

  def verify
    domain = find_domain

    check = domain.verify!
    if check.success?
      redirect_to edit_organization_path(@organization), notice: t("organizations.domains.verify_result.verified", domain: domain.domain)
    else
      redirect_to edit_organization_path(@organization), alert: t("organizations.domains.verify_result.failed", domain: domain.domain)
    end
  rescue OrganizationDomain::DnsCheck::Error
    redirect_to edit_organization_path(@organization), alert: t("organizations.domains.verify_result.unavailable", domain: domain.domain)
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
