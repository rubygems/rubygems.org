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
    arr = []

    ary.each do |full_name, count|
      version = Version.find_by(full_name: full_name)
      next unless version

      # Gem version count
      increment(count, rubygem_id: version.rubygem_id, version_id: version.id)

      arr << [version, full_name, count]
    end

    grouped_gems = arr.group_by do |version, _, _|
      version.rubygem_id
    end
    grouped_gems.each do |rubygem_id, counts|
      count = counts.sum { |_, _, c| c }
      # Gem count
      increment(count, rubygem_id: rubygem_id, version_id: 0)
    end

    total_count = arr.sum { |_, _, c| c }
    # Total count
    increment(total_count, rubygem_id: 0, version_id: 0)
  end
end
