require 'memcached'

class V1MarshaledDepedencies

  LIMIT = 250

  BadRequest = [404, {}, ["Go away"]]
  TooMany =    [413, {}, 
                ["Too many gems to resolve, please request less than #{LIMIT}"]]

  def data_for(name)
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
    end

    # Strip off the version header
    str = Marshal.dump(these)
    val = str[3].ord

    if val == 0 or val > 4
      m = str[4..-1]
    else
      m = str[4+val..-1]
    end

    [these.size, m]
  end

  CACHE = Memcached.new("localhost:11211")

  def call(env)
    request = Rack::Request.new(env)

    return BadRequest unless request.path == "/api/v1/dependencies"

    gems = request.params['gems']

    return BadRequest unless gems

    gems = gems.split(",")

    return TooMany if gems.size > LIMIT

    total = 0
    body = []
    cache = CACHE.clone

    gems.each do |g|
      key = "gem.#{g}"

      begin
        n, m = cache.get(key).split(":",2)

        total += n.to_i
        body << m
      rescue Memcached::NotFound
        begin
          n, m = data_for(g)

          cache.set key, "#{n}:#{m}"

          total += n
          body << m
        rescue
          return BadRequest
        end
      rescue Memcached::ServerIsMarkedDead
        begin
          n, m = data_for(g)

          total += n
          body << m
        rescue
          return BadRequest
        end
      end
    end

    body.unshift "\x04\x08[\x04#{[total].pack('V')}"

    [200, {}, body]
  end
end
