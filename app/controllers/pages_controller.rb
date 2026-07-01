# frozen_string_literal: true

class PagesController < ApplicationController
  before_action :find_page, only: :show

  layout "hammy"

  def show
    add_breadcrumb t("pages.#{@page}.title")
    render @page
  end

  def sponsors
    redirect_to page_path(id: "supporters"), status: :moved_permanently
  end

  private

  def find_page
    id = params[:id]
    raise ActionController::RoutingError, "Page not found" unless Gemcutter::PAGES.include?(id)
    @page = id
  end
end
