class FastlyPurgeJob < ApplicationJob
  queue_as :default

  class PassPathXorKeyError < ArgumentError
  end

  discard_on PassPathXorKeyError

  before_perform do
    raise PassPathXorKeyError, arguments.first.inspect if arguments.first.slice(:path, :key).compact.size != 1
  end

  def perform(soft:, path: nil, key: nil)
    if path
      Fastly.purge({ path:, soft: })
    elsif key
      Fastly.purge_key(key, soft:)
    end
  end
end
