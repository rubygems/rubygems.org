class PagesController < ApplicationController
  before_action :find_page, only: :show

  layout "hammy"

  def show
    add_breadcrumb t("pages.#{@page}.title")
    render @page
  end

  private

  def find_page
    id = params[:id]
    raise ActionController::RoutingError, "Page not found" unless Gemcutter::PAGES.include?(id)
    @page = id
  end
end
