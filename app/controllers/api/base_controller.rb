class Api::BaseController < ApplicationController
  before_action :doorkeeper_authorize!, if: :doorkeeper_token
  before_action :authenticate_with_oauth, if: :doorkeeper_token

  private

  def authenticate_with_oauth
    sign_in User.find_by_id(doorkeeper_token.resource_owner_id)
  end

  def find_rubygem_by_name
    @url      = params[:url]
    @gem_name = params[:gem_name] || params[:rubygem_name]
    @rubygem  = Rubygem.find_by_name(@gem_name)
    return if @rubygem || @gem_name == WebHook::GLOBAL_PATTERN
    render plain: "This gem could not be found", status: :not_found
  end
end
