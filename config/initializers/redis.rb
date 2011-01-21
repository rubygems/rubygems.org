if Rails.env.test? || Rails.env.cucumber?
  $redis = Redis.new(:db => 1)
else
  $redis = Redis.connect(:url => ENV['REDISTOGO_URL'])
end
