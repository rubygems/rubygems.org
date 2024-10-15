class PagesController < ApplicationController
  before_action :find_page

  layout "hammy"

  def show
    add_breadcrumb t("pages.#{@page}.title")
    render @page
  end

  private

  def find_page
    id = params.permit(:id).require(:id)
    raise ActionController::RoutingError, "Page not found" unless Gemcutter::PAGES.include?(id)
    @page = id
  end
end
