class PagesController < ApplicationController
  before_action :find_page

  def show
    render @page
  end

  private

  def find_page
    id = params.permit(:id).require(:id)
    raise ActionController::RoutingError, "Page not found" unless Gemcutter::PAGES.include?(id)
    @page = id
  end
end
