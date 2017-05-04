require 'gem_dependent'

class GemDependentV2 < GemDependent
  private

  def build_gem_payload(dep_key, dependencies)
    {
      name:                      dep_key.name,
      number:                    dep_key.number,
      platform:                  dep_key.platform,
      required_ruby_version:     dep_key.required_ruby_version,
      required_rubygems_version: dep_key.required_rubygems_version,
      checksum:                  dep_key.info_checksum,
      dependencies:              dependencies
    }
  end

  def gem_cache_key(g)
    "deps/v2/#{g}"
  end

  def statsd_hit_key
    'gem_dependent.v2.memcached.hit'
  end

  def statsd_miss_key
    'gem_dependent.v2.memcached.miss'
  end
end
