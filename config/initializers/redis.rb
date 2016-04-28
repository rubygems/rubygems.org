if Rails.env.test? && Toxiproxy.running?
  port = 22_220
  Toxiproxy.populate([{
                       name: "redis",
                       listen: "127.0.0.1:#{port}",
                       upstream: "127.0.0.1:6379"
                     }])
  Redis.current = Redis.new(db: 1, port: port)
else
  Redis.current = Redis.new(url: ENV['REDIS_URL'])
end
