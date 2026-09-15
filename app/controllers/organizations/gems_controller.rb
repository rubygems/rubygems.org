# frozen_string_literal: true

class Organizations::GemsController < Organizations::BaseController
  skip_before_action :redirect_to_signin, only: %i[index]

  layout "subject"

  def index
    @gems = @organization.rubygems.with_versions.by_downloads.preload(:most_recent_version, :gem_download).load_async
    @gems_count = @organization.rubygems.with_versions.count
  end
end
