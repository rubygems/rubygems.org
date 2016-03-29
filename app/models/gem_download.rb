class GemDownload < ActiveRecord::Base
  belongs_to :rubygem
  belongs_to :version

  scope :most_downloaded_gems, -> { where("version_id != 0").includes(:version).order(count: :desc) }

  def self.count_for_version(id)
    v = Version.find(id)
    return 0 unless v
    download = GemDownload.find_by(rubygem_id: v.rubygem_id, version_id: v.id)
    if download
      download.count
    else
      0
    end
  end

  def self.count_for_rubygem(id)
    download = GemDownload.find_by(rubygem_id: id, version_id: 0)
    if download
      download.count
    else
      0
    end
  end

  def self.total_count
    download = GemDownload.find_by(rubygem_id: 0, version_id: 0)
    if download
      download.count
    else
      0
    end
  end

  def self.increment(count, rubygem_id:, version_id: 0)
    scope = GemDownload.where(rubygem_id: rubygem_id).select("id")
    scope = scope.where(version_id: version_id)
    sql = scope.to_sql

    update = "UPDATE #{quoted_table_name} SET count = count + ? WHERE id = (#{sql}) RETURNING *"

    # TODO: Remove this comments, once we move to GemDownload only.
    # insert = "INSERT INTO #{quoted_table_name} (rubygem_id, version_id, count) SELECT ?, ?, ?"
    # find_by_sql(["WITH upsert AS (#{update}) #{insert} WHERE NOT EXISTS (SELECT * FROM upsert)", count, rubygem_id, version_id, count]).first
    find_by_sql([update, count]).first
  end

  # Takes an array where members have the form
  #   [full_name, count]
  # E.g.:
  #   ['rake-10.4.2', 1]
  def self.bulk_update(ary)
    updates_by_version = {}
    updates_by_gem = {}

    ary.each do |full_name, count|
      if updates_by_version.key?(full_name)
        version, old_count = updates_by_version[full_name]
        updates_by_version[full_name] = [version, old_count + count]
      else
        version = Version.find_by(full_name: full_name)
        updates_by_version[full_name] = [version, count] if version
      end
    end

    updates_by_version.values.each do |version, version_count|
      updates_by_gem[version.rubygem_id] ||= 0
      updates_by_gem[version.rubygem_id] += version_count
    end

    updates_by_version.values.sort_by { |v, _| v.id }.each do |version, count|
      # Gem version count
      increment(count, rubygem_id: version.rubygem_id, version_id: version.id)
    end

    updates_by_gem.sort_by { |id, _| id }.each do |rubygem_id, count|
      # Gem count
      increment(count, rubygem_id: rubygem_id, version_id: 0)
    end

    total_count = updates_by_gem.values.sum
    # Total count
    increment(total_count, rubygem_id: 0, version_id: 0)
  end
end
