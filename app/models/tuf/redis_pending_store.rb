module Tuf
  # The pending store is a place to keep a record of all files that have yet to
  # be added to TUF, so that the next re-index will pick them up.
  #
  # TODO: Don't use Marshal
  class RedisPendingStore
    def initialize(redis, namespace = "rubygems.org:tuf:")
      @redis     = redis
      @namespace = namespace
    end

    def add(files)
      files.each do |x|
        redis.lpush(pending_key, Marshal.dump(x))
      end
    end

    # After pending files have been successfully processed, they should be
    # passed back to the clear method.
    def pending
      redis.lrange(pending_key, 0, -1).map {|x| Marshal.load(x) }
    end

    # Clears files after they have been successfully processed. This will be
    # most efficient if you pass files in the same order that they were
    # returned from pending.
    def clear(files)
      files.each do |x|
        redis.lrem(pending_key, 0, Marshal.dump(x))
      end
    end

    private

    def pending_key
      namespace + "pending"
    end

    attr_reader :redis, :namespace
  end
end
