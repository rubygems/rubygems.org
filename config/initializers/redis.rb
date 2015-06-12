if Rails.env.test?
  Redis.current = Redis.new(db: 1)
else
  Redis.current = Redis.new(url: ENV['REDISTOGO_URL'])
end
