class Api::BaseController < ApplicationController
  private

  def find_rubygem_by_name
    @gem_name = params[:gem_name] || params[:rubygem_name]
    @rubygem  = Rubygem.find_by_name(@gem_name)
    return if @rubygem || @gem_name == WebHook::GLOBAL_PATTERN
    render plain: "This gem could not be found", status: :not_found
  end

  def validate_gem_and_version
    if !@rubygem.hosted?
      render plain: t(:this_rubygem_could_not_be_found),
             status: :not_found
    elsif !@rubygem.owned_by?(current_user)
      render plain: "You do not have correct permission to perform this action.",
             status: :forbidden
    else
      begin
        slug = if params[:platform].blank?
                 params[:version]
               else
                 "#{params[:version]}-#{params[:platform]}"
               end
        @version = Version.find_from_slug!(@rubygem, slug)
      rescue ActiveRecord::RecordNotFound
        render plain: "The version #{params[:version]} does not exist.",
               status: :not_found
      end
    end
  end
end
