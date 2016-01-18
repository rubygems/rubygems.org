## TODO: wrap better our client and lazy load the redis require
require 'redis'

if Rails.env.test?
  require 'toxiproxy'

  port = Toxiproxy.running? ? 22_220 : 6379
  if Toxiproxy.running?
    Toxiproxy.populate(
      [
        {
          name: "redis",
          listen: "127.0.0.1:#{port}",
          upstream: "127.0.0.1:6379"
        }
      ]
    )
  end
  Redis.current = Redis.new(db: 1, port: port)
else
  Redis.current = Redis.new(url: ENV['REDIS_URL'])
end
