if Rails.env.test?
  $redis = Redis.new(:db => 1)
elsif Rails.env.recovery?
  require "fakeredis"
  $redis = Redis.new
else
  $redis = Redis.connect(:url => ENV['REDISTOGO_URL'])
end
