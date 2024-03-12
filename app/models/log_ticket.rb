class LogTicket < ApplicationRecord
  enum backend: { s3: 0, local: 1 }
  enum status: %i[pending processing failed processed].index_with(&:to_s)

  def self.pop(key: nil, directory: nil)
    scope = pending.limit(1).lock(true).order("id ASC")
    scope = scope.where(key: key) if key
    scope = scope.where(directory: directory) if directory
    scope.sole.tap do |ticket|
      ticket.update_column(:status, "processing")
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
