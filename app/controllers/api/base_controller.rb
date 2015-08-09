class Api::BaseController < ApplicationController
  skip_before_action :require_ssl

  private

  def find_rubygem_by_name
    @url      = params[:url]
    @gem_name = params[:gem_name]
    @rubygem  = Rubygem.find_by_name(@gem_name)
    return if @rubygem || @gem_name == WebHook::GLOBAL_PATTERN
    render text: "This gem could not be found", status: :not_found
  end

  def render_as value
    respond_to do |format|
      format.json { render json: value }
      format.yaml { render yaml: value }
    end
  end
end
