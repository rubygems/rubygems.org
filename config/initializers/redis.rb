if Rails.env.test?
  Redis.current = Redis.new(db: 1)
elsif Rails.env.recovery?
  require "fakeredis"
else
  Redis.current = Redis.new(url: ENV['REDISTOGO_URL'])
end
