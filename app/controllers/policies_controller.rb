class PoliciesController < ApplicationController
  before_action :find_policy, only: :show

  layout "hammy"

  def index
    add_breadcrumb t(".title")
  end

  def show
    add_breadcrumb t("policies.index.title"), policies_path
    add_breadcrumb t("policies.#{@page}.title")
    render @page
  end

  private

  def find_policy
    id = params[:policy]
    raise ActionController::RoutingError, "Policy page not found" unless Gemcutter::POLICY_PAGES.include?(id)
    @page = id
  end
end
