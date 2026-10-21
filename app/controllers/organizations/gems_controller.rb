# frozen_string_literal: true

class Organizations::GemsController < Organizations::BaseController
  include GemSortable

  skip_before_action :redirect_to_signin, only: %i[index]
  before_action :set_gem_sort, only: :index
  before_action :set_page, only: :index

  layout "subject"

  def index
    @gems = @organization.rubygems.with_versions.name_matches(params[:gem_filter]).sorted_by(@gem_sort)
      .page(@page).preload(:most_recent_version, :gem_download).load_async
    @gems_count = @organization.rubygems.with_versions.count
  end
end
