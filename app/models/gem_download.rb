class GemDownload < ActiveRecord::Base
  belongs_to :rubygem
  belongs_to :version

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

  def self.update_count_by(count, rubygem_id:, version_id: 0)
    scope = GemDownload.where(rubygem_id: rubygem_id).select("id")
    scope = scope.where(version_id: version_id)
    sql = scope.to_sql

    update = "UPDATE #{quoted_table_name} SET count = count + ? WHERE id = (#{sql}) RETURNING *"

    # TODO: Remove this comments, once we move to GemDownload only.
    # insert = "INSERT INTO #{quoted_table_name} (rubygem_id, version_id, count) SELECT ?, ?, ?"
    # find_by_sql(["WITH upsert AS (#{update}) #{insert} WHERE NOT EXISTS (SELECT * FROM upsert)", count, rubygem_id, version_id, count]).first
    find_by_sql([update, count]).first
  end

  def self.increment(name, full_name, count: 1)
    transaction do
      gem = Rubygem.find_by(name: name)
      version = Version.find_by(full_name: full_name)
      return unless gem && version
      # Total count
      update_count_by(count, rubygem_id: 0, version_id: 0)
      # Gem count
      update_count_by(count, rubygem_id: gem.id, version_id: 0)
      # Gem version count
      update_count_by(count, rubygem_id: gem.id, version_id: version.id)
    end
  end

  # Takes an array where members have the form
  #   [name, full_name, count]
  # E.g.:
  #   ['rake', 'rake-10.4.2', 1]
  def self.bulk_update(ary)
    ary.each do |name, full_name, count|
      increment(name, full_name, count: count)
    end
  end
end
