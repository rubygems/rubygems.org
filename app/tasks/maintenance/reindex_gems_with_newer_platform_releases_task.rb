# frozen_string_literal: true

# A gem whose newest release is for a platform other than ruby used to be
# indexed with an older ruby release as its latest version. Reindex those gems
# so search shows the same release as the gem page.
class Maintenance::ReindexGemsWithNewerPlatformReleasesTask < MaintenanceTasks::Task
  def collection
    newer_platform_releases = Version.latest.where.not(platform: "ruby").where(<<~SQL.squish)
      versions.position < (
        SELECT MIN(ruby_releases.position) FROM versions ruby_releases
        WHERE ruby_releases.rubygem_id = versions.rubygem_id
          AND ruby_releases.latest AND ruby_releases.platform = 'ruby'
      )
    SQL
    Rubygem.where(id: newer_platform_releases.select(:rubygem_id))
  end

  def process(rubygem)
    rubygem.reindex
  end
end
