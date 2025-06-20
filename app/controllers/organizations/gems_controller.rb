class Organizations::GemsController < Organizations::BaseController
  before_action :find_organization, only: %i[index]

  layout "subject"

  def index
    @gems = @organization.rubygems.with_versions.by_downloads.preload(:most_recent_version, :gem_download).load_async
    @gems_count = @organization.rubygems.with_versions.count
  end

  private

  def find_organization
    @organization = Organization.find_by_handle!(params[:organization_id])
  end
end
