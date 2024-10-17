class Onboarding::BaseController < ApplicationController
  before_action :redirect_to_signin, unless: :signed_in?
  before_action :redirect_to_new_mfa, if: :mfa_required_not_yet_enabled?
  before_action :find_or_initialize_onboarding

  def find_or_initialize_onboarding
    @organization_onboarding = OrganizationOnboarding.find_or_initialize_by(created_by: Current.user, status: :pending)
  end
end
