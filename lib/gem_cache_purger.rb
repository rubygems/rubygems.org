class GemCachePurger
  def self.call(gem_name)
    # We need to purge from Fastly and from Memcached
    ["info/#{gem_name}", "names"].each do |path|
      Rails.cache.delete(path)
      Fastly.delay.purge(path: path, soft: true)
    end

    Rails.cache.delete("deps/v1/#{gem_name}")
    Fastly.delay.purge(path: "versions", soft: true)
    Fastly.delay.purge(path: "gem/#{gem_name}", soft: true)
  end
end
