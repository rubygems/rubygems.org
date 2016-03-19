class GemDownload < ActiveRecord::Base
  belongs_to :rubygem
  belongs_to :version

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
    scope = GemDownload.where(rubygem_id: rubygem_id).select("id").lock(true)
    scope = scope.where(version_id: version_id)
    sql = scope.to_sql
    find_by_sql(["UPDATE #{quoted_table_name} SET count = count + ? WHERE id = (#{sql}) RETURNING *", count]).first
  end

  # Takes an array where members have the form
  #   [name, full_name, count]
  # E.g.:
  #   ['rake', 'rake-10.4.2', 1]
  def self.bulk_update(ary)
    ary.each do |name, full_name, count|
      transaction do
        gem = Rubygem.find_by(name: name)
        version = Version.find_by(full_name: full_name)
        # Total count
        increment(count, rubygem_id: 0, version_id: 0)
        # Gem count
        increment(count, rubygem_id: gem.id, version_id: 0) if gem
        # Gem version count
        increment(count, rubygem_id: gem.id, version_id: version.id) if version
      end
    end
  end
end
