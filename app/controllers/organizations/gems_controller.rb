# frozen_string_literal: true

class Organizations::GemsController < Organizations::BaseController
  include GemSortable

  skip_before_action :redirect_to_signin, only: %i[index]
  before_action :set_gem_sort, only: :index

  layout "subject"

  def index
    @gems = @organization.rubygems.with_versions.sorted_by(@gem_sort).preload(:most_recent_version, :gem_download).load_async
    @gems_count = @organization.rubygems.with_versions.count
  end
end
