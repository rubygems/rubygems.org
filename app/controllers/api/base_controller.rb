class Api::BaseController < ApplicationController
  skip_before_action :require_ssl

  private

  def find_rubygem_by_name
    @url      = params[:url]
    @gem_name = params[:gem_name] || params[:rubygem_name]
    @rubygem  = Rubygem.find_by_name(@gem_name)
    return if @rubygem || @gem_name == WebHook::GLOBAL_PATTERN
    render text: "This gem could not be found", status: :not_found
  end

  def validate_gem_and_version
    if !@rubygem.hosted?
      render text: t(:this_rubygem_could_not_be_found),
             status: :not_found
    elsif !@rubygem.owned_by?(current_user)
      render text: "You do not have permission to mark this gem as vulnerable.",
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
        render text: "The version #{params[:version]} does not exist.",
               status: :not_found
      end
    end
  end
end
