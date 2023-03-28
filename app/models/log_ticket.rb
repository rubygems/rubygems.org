class LogTicket < ApplicationRecord
  enum backend: { s3: 0, local: 1 }
  enum status: %i[pending processing failed processed].index_with(&:to_s)

  def self.pop(key: nil, directory: nil)
    scope = pending.limit(1).lock(true).select("id").order("id ASC")
    scope = scope.where(key: key) if key
    scope = scope.where(directory: directory) if directory
    sql = scope.to_sql

    find_by_sql(["UPDATE #{quoted_table_name} SET status = ? WHERE id IN (#{sql}) RETURNING *", "processing"]).first
  end

  def fs
    @fs ||=
      if s3?
        RubygemFs::S3.new(bucket: directory)
      else
        RubygemFs::Local.new(directory)
      end
  end

  def body
    fs.get(key)
  end
end
