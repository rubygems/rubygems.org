class Organizations::Onboarding::BaseController < ApplicationController
  before_action :redirect_to_signin, unless: :signed_in?
  before_action :redirect_to_new_mfa, if: :mfa_required_not_yet_enabled?
  before_action :find_or_initialize_onboarding
  before_action :set_breadcrumbs

  layout "onboarding"

  def find_or_initialize_onboarding
    @organization_onboarding = OrganizationOnboarding.find_or_initialize_by(created_by: Current.user, status: :pending)
  end

  def set_breadcrumbs
    add_breadcrumb t("breadcrumbs.dashboard"), dashboard_path
    add_breadcrumb "Create Org"
  end

  def available_rubygems
    @available_rubygems ||= @organization_onboarding.available_rubygems.to_a.tap do |gems|
      namesake_rubygem = @organization_onboarding.namesake_rubygem
      gems.unshift gems.delete(namesake_rubygem) if namesake_rubygem
    end
  end
  helper_method :available_rubygems

  def approved_invites
    @approved_invites ||= @organization_onboarding.approved_invites
  end
  helper_method :approved_invites
end
