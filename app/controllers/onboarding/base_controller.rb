class Onboarding::BaseController < ApplicationController
  before_action :redirect_to_signin, unless: :signed_in?
  before_action :redirect_to_new_mfa, if: :mfa_required_not_yet_enabled?
  before_action :find_or_initialize_onboarding
  before_action :set_breadcrumbs

  def find_or_initialize_onboarding
    @organization_onboarding = OrganizationOnboarding.find_or_initialize_by(created_by: Current.user, status: :pending)
  end

  def set_breadcrumbs
    add_breadcrumb t("breadcrumbs.dashboard"), dashboard_path
    add_breadcrumb "Create Org"
  end

  def available_rubygems
    @available_rubygems ||= begin
      gems = @organization_onboarding.available_rubygems.to_a
      gems.unshift gems.delete(@organization_onboarding.namesake_rubygem) if @organization_onboarding.namesake_rubygem
      gems
    end
  end
  helper_method :available_rubygems
end
