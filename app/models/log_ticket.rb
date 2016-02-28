class LogTicket < ActiveRecord::Base
  enum backend: [:s3, :local]

  scope :pending, -> { limit(1).lock(true).select("id").where(status: "pending").order("id ASC") }

  def self.pop(key = nil, directory = nil)
    scope = pending
    scope = scope.where(key: key) if key
    scope = scope.where(directory: directory) if directory
    sql = scope.to_sql

    find_by_sql(["UPDATE #{quoted_table_name} SET status = ? WHERE id IN (#{sql}) RETURNING *", 'processing']).first
  end

  def filesystem
    @fs ||=
      if s3?
        RubygemFs::S3.new(access_key_id: ENV['S3_KEY'],
                          secret_access_key: ENV['S3_SECRET'],
                          region: Gemcutter.config['s3_region'],
                          endpoint: "https://#{Gemcutter.config['s3_endpoint']}",
                          bucket: directory)
      else
        RubygemFs::Local.new(directory)
      end
  end
end
