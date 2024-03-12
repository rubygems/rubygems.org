module LatestVersion
  extend ActiveSupport::Concern

  included do
    def latest_version
      @latest_version ||= @rubygem.most_recent_version
    end

    def latest_version_by_slug
      @latest_version = @rubygem.find_version_by_slug!(params.require(:version_id))
    end
  end
end
