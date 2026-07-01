# frozen_string_literal: true

class PagesController < ApplicationController
  before_action :find_page, only: :show

  PAGE_PARENTS = {
    "security-engineers-in-residence-faq" => "security"
  }.freeze

  layout "hammy"

  def show
    add_page_parent_breadcrumb
    add_breadcrumb t("pages.#{@page}.title")
    render @page
  end

  private

  def find_page
    id = params[:id]
    raise ActionController::RoutingError, "Page not found" unless Gemcutter::PAGES.include?(id)
    @page = id
  end

  def add_page_parent_breadcrumb
    return unless (parent = PAGE_PARENTS[@page])

    add_breadcrumb t("pages.#{parent}.title"), page_path(parent)
  end
end
