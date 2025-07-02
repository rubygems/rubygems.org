class PoliciesController < ApplicationController
  before_action :find_policy, only: :show
  before_action :redirect_to_signin, unless: :signed_in?, only: %i[acknowledge]

  layout "hammy"

  def index
    add_breadcrumb t(".title")
  end

  def show
    add_breadcrumb t("policies.index.title"), policies_path
    add_breadcrumb t("policies.#{@page}.title")
    render @page
  end

  def acknowledge
    current_user.acknowledge_policies!
    redirect_back_or_to root_path
  end

  def method_not_allowed
    response.headers["Allow"] = "GET"
    head :method_not_allowed
  end

  private

  def find_policy
    id = params[:policy]
    raise ActionController::RoutingError, "Policy page not found" unless Gemcutter::POLICY_PAGES.include?(id)
    @page = id
  end
end
