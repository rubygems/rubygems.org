require 'memcached'

class V1MarshaledDepedencies

  LIMIT = 250

  BadRequest = [404, {}, ["Go away"]]
  TooMany =    [413, {}, 
                ["Too many gems to resolve, please request less than #{LIMIT}"]]

  def data_for(name, ary, cache)
    gem = Rubygem.find_by_name(name)
    raise "Unknown gem - #{name}" unless gem

    these = []

    gem.versions.order(:number).reverse_each do |ver|
      deps = ver.dependencies.find_all { |d| d.scope == "runtime" }

      data = {
        :name => name,
        :number => ver.number,
        :platform => ver.platform,
        :dependencies => deps.map { |d| [d.name, d.requirements] }
      }
      these << data
      ary << data
    end

    if cache
      cache.set "gem.#{name}", [Marshal.dump(these)].pack("m")
    end

    ary
  end

  CACHE = Memcached.new("localhost:11211")

  def call(env)
    request = Rack::Request.new(env)

    return BadRequest unless request.path == "/api/v1/dependencies"

    gems = request.params['gems']

    return BadRequest unless gems

    gems = gems.split(",")

    return TooMany if gems.size > LIMIT

    ary = []
    cache = CACHE.clone

    gems.each do |g|
      begin
        data = cache.get "gem.#{g}"
        ary += Marshal.load(data.unpack("m").first)
      rescue Memcached::NotFound
        begin
          data_for g, ary, cache
        rescue
          return BadRequest
        end
      rescue Memcached::ServerIsMarkedDead
        begin
          data_for g, ary, nil
        rescue
          return BadRequest
        end
      end
    end

    body = Marshal.dump ary

    [200, {}, [body]]
  end
end
