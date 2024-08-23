# Mimic LogTicket model to store the log files but for the downloads database.
# It will be backfilled with the log files from the main database to the downloads database.
# There will be a background job to process the log files
class LogDownload < DownloadsDB
  enum backend: { s3: 0, local: 1 }
  enum status: %i[pending processing failed processed].index_with(&:to_s)
  
  def self.pop(key: nil, directory: nil)
    scope = pending.limit(1).order("id ASC")
    scope = scope.where(key: key) if key
    scope = scope.where(directory: directory) if directory
    scope.lock(true).sole.tap do |log_download|
      log_download.update_column(:status, "processing")
    end
  rescue ActiveRecord::RecordNotFound
    nil # no ticket in queue found by `sole` call
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