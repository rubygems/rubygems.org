module LatestVersion
  extend ActiveSupport::Concern

  included do
    def latest_version
      @latest_version ||= @rubygem.versions.most_recent
    end

    def latest_version_by_slug
      @latest_version = Version.find_by!(full_name: "#{params[:rubygem_id]}-#{params[:version_id]}")
    end
  end
end
