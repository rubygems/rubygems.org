if Rails.env.test? || Rails.env.cucumber?
  $redis = Redis.new(:db => 1)
else
  $redis = Redis.new(:db => 0)
end
