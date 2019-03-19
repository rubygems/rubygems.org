class Api::BaseController < ApplicationController
  private

  def find_rubygem_by_name
    @gem_name = params[:gem_name] || params[:rubygem_name]
    @rubygem  = Rubygem.find_by_name(@gem_name)
    return if @rubygem || @gem_name == WebHook::GLOBAL_PATTERN
    render plain: "This gem could not be found", status: :not_found
  end

  def enqueue_web_hook_jobs(version)
    jobs = version.rubygem.web_hooks + WebHook.global
    jobs.each do |job|
      job.fire(
        request.protocol.delete("://"),
        request.host_with_port,
        version.rubygem,
        version
      )
    end
  end
end
