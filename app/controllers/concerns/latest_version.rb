module LatestVersion
  extend ActiveSupport::Concern

  included do
    def latest_version
      @latest_version ||= @rubygem.versions.most_recent
    end
  end
end
