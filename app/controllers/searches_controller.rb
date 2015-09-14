require 'will_paginate/array'

class SearchesController < ApplicationController
  before_action :set_page, only: :show

  def show
    return unless params[:query] && params[:query].is_a?(String)
    @gems = SwiftypeSearch.search(params[:query]).paginate(:page => params[:page])
    @exact_match = Rubygem.name_is(params[:query]).with_versions.first
    redirect_to rubygem_path(@exact_match) if @gems == [@exact_match]
  end
end
