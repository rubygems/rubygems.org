# frozen_string_literal: true

class Organizations::BaseController < ApplicationController
  before_action :redirect_to_signin, unless: :signed_in?
  before_action :redirect_to_new_mfa, if: :mfa_required_not_yet_enabled?
  before_action :redirect_to_settings_strong_mfa_required, if: :mfa_required_weak_level_enabled?
  before_action :find_organization

  layout "subject"

  private

  def find_organization
    @organization = Organization.find_by_handle!(params[:organization_id])
  end

  # Rendered by organizations/_domains on the settings page.
  def set_domain_settings
    @domains = @organization.domains.order(:created_at, :id).to_a
    @latest_checks = OrganizationDomainCheck.latest_by_domain_id(@domains.map(&:id))
  end
end
