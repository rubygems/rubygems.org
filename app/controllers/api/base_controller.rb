# frozen_string_literal: true

class Api::BaseController < ApplicationController
  private

  def find_rubygem_by_name
    @gem_name = params[:gem_name] || params[:rubygem_name]
    @rubygem  = Rubygem.find_by_name(@gem_name)
    return if @rubygem || @gem_name == WebHook::GLOBAL_PATTERN
    render plain: "This gem could not be found", status: :not_found
  end
end
