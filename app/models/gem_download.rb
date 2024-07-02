class GemDownload < ApplicationRecord
  belongs_to :rubygem, optional: true
  belongs_to :version, optional: true

  scope(:most_downloaded_gems, -> { for_versions.includes(:version).order(count: :desc) })
  scope(:for_versions, -> { where.not(version_id: 0) })
  scope(:for_rubygems, -> { where(version_id: 0) })
  scope(:total, -> { where(version_id: 0, rubygem_id: 0) })

  class << self
    def for_all_gems
      GemDownload.create_with(count: 0).find_or_create_by!(version_id: 0, rubygem_id: 0)
    end

    def count_for_version(id)
      v = Version.find(id)
      return 0 unless v

      count_for(rubygem_id: v.rubygem_id, version_id: v.id)
    end

    def count_for_rubygem(id)
      count_for(rubygem_id: id)
    end

    def total_count
      count_for
    end

    # version_id: 0 stores count for total gem downloads
    # we need to find the second maximum
    def most_downloaded_gem_count
      count_by_sql "SELECT MAX(count) FROM gem_downloads WHERE rubygem_id <> 0"
    end

    def increment(count, rubygem_id:, version_id: 0)
      scope = GemDownload.where(rubygem_id: rubygem_id).select("id")
      scope = scope.where(version_id: version_id)
      return scope.first if count.zero?

      # TODO: Remove this comments, once we move to GemDownload only.
      # insert = "INSERT INTO #{quoted_table_name} (rubygem_id, version_id, count) SELECT ?, ?, ?"
      # find_by_sql(["WITH upsert AS (#{update}) #{insert} WHERE NOT EXISTS (SELECT * FROM upsert)", count, rubygem_id, version_id, count]).first
      scope.update_all(["count = count + ?", count])
    end

    # Takes an array where members have the form
    #   [full_name, count]
    # E.g.:
    #   ['rake-10.4.2', 1]
    def bulk_update(ary)
      updates_by_gem = {}
      updates_by_version = init_updates_by_version(ary)

      ary.each do |full_name, count|
        if updates_by_version.key?(full_name)
          version, old_count = updates_by_version[full_name]
          updates_by_version[full_name] = [version, old_count + count]
        end
      end

      return if updates_by_version.empty?

      total_count = 0
      updates_by_version.each_value.each_slice(1_000) do |versions|
        rubygem_ids = []
        version_ids = []
        downloads = []
        versions.each do |(version, version_count)|
          updates_by_gem[version.rubygem_id] ||= 0
          updates_by_gem[version.rubygem_id] += version_count

          total_count += version_count

          rubygem_ids << version.rubygem_id
          version_ids << version.id
          downloads << version_count
        end
        increment_versions(rubygem_ids, version_ids, downloads)
      end

      update_gem_downloads(updates_by_gem)

      # Total count
      increment(total_count, rubygem_id: 0, version_id: 0)
    end

    private

    def count_for(rubygem_id: 0, version_id: 0)
      count = GemDownload.where(rubygem_id: rubygem_id, version_id: version_id).pick(:count)
      count || 0
    end

    # updates the downloads field of rubygems in DB and ES index
    # input: { rubygem_id => download_count_to_increment }
    def update_gem_downloads(updates_by_gem)
      updates_by_version = most_recent_version_downloads(updates_by_gem.keys)

      bulk_update_query = downloads_by_gem(updates_by_gem.keys).map do |id, downloads|
        update_query(id, downloads + updates_by_gem[id], updates_by_version[id])
      end
      increment_rubygems(updates_by_gem.keys, updates_by_gem.values)

      # update ES index of rubygems
      Searchkick.client.bulk body: bulk_update_query
    rescue Faraday::ConnectionFailed, Searchkick::Error, OpenSearch::Transport::Transport::Error => e
      logger.debug { { message: "ES update failed", exception: e, updates_by_gem: } }
    end

    def increment_versions(rubygem_ids, version_ids, downloads)
      query = <<~SQL.squish
        count = #{quoted_table_name}.count + updates_by_gem.downloads
        FROM
          (SELECT UNNEST(ARRAY[?]) AS r_id, UNNEST(ARRAY[?]) AS v_id, UNNEST(ARRAY[?]) AS downloads) AS updates_by_gem
        WHERE #{quoted_table_name}.rubygem_id = updates_by_gem.r_id AND #{quoted_table_name}.version_id = updates_by_gem.v_id
      SQL
      update_all([query, rubygem_ids, version_ids, downloads])
    end

    def increment_rubygems(rubygem_ids, downloads)
      query = <<~SQL.squish
        count = #{quoted_table_name}.count + updates_by_gem.downloads
        FROM
          (SELECT UNNEST(ARRAY[?]) AS r_id, UNNEST(ARRAY[?]) AS downloads) AS updates_by_gem
        WHERE #{quoted_table_name}.rubygem_id = updates_by_gem.r_id AND #{quoted_table_name}.version_id = 0
      SQL
      update_all([query, rubygem_ids, downloads])
    end

    def downloads_by_gem(rubygem_ids)
      where(rubygem_id: rubygem_ids, version_id: 0)
        .order(:rubygem_id)
        .pluck(:rubygem_id, :count)
    end

    def update_query(id, downloads, version_downloads)
      { update: { _index: "rubygems-#{Rails.env}",
                  _id: id,
                  data: { doc: { downloads: downloads, version_downloads: version_downloads } } } }
    end

    def init_updates_by_version(ary)
      full_names = ary.map { |full_name, _| full_name }.uniq
      versions = Version.select(:full_name, :rubygem_id, :id).where(full_name: full_names)

      versions.each_with_object({}) do |version, hash|
        hash[version.full_name] = [version, 0]
      end
    end

    def most_recent_version_downloads(rubygem_ids)
      latest_downloads = joins(:version).merge(Version.latest.where(platform: "ruby")).where(rubygem_id: rubygem_ids)

      updates_by_version = latest_downloads.each_with_object({}) { |download, hash| hash[download.rubygem_id] = download.count }
      # use most_recent_version to get downloads count missing in latest_downloads
      rubygem_ids.each { |id| updates_by_version[id] = Rubygem.find(id).most_recent_version.downloads_count unless updates_by_version[id] }

      updates_by_version
    end
  end
end
