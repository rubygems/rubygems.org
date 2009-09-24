if ENV['MEMCACHE_SERVERS']
  require 'memcache'
  require 'rack/cache'
  CACHE = ::MemCache.new(ENV['MEMCACHE_SERVERS'].split(','), :namespace => ENV['MEMCACHE_NAMESPACE'])
end
