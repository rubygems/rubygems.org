class GemCachePurger
  def self.call(gem_name)
    # We need to purge from Fastly and from Memcached
    ["deps/v1/#{gem_name}", "info/#{gem_name}", "names"].each do |path|
      Rails.cache.delete(path)
      Fastly.delay.purge(path)
    end
  end
end
