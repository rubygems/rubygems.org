module LatestVersion
  extend ActiveSupport::Concern

  included do
    def latest_version
      @latest_version ||= @rubygem.versions.most_recent
    end

    def latest_version_by_slug
      @latest_version = @rubygem.find_version_by_slug!(params.require(:version_id))
    end
  end
end
