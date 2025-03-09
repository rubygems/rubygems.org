class PagesController < ApplicationController
  before_action :find_page, except: :policies

  layout "hammy"

  def show
    add_breadcrumb t("pages.#{@page}.title")
    render @page
  end

  def policies
    policy_page = params[:id]
    raise ActionController::RoutingError, "Policy page not found" unless Gemcutter::POLICY_PAGES.include?(policy_page)

    add_breadcrumb t("pages.#{policy_page}.title")
    @markdown_content = Rails.root.join("app", "views", "pages", "#{policy_page}.md").read
  end

  private

  def find_page
    id = params[:id]
    raise ActionController::RoutingError, "Page not found" unless Gemcutter::PAGES.include?(id)
    @page = id
  end
end
