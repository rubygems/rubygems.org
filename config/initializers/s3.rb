if ENV['S3_KEY'] && ENV['S3_SECRET']
  Fog.mock! if Rails.env.test?

  $fog = Fog::Storage.new(
    :provider               => 'AWS',
    :aws_access_key_id      => ENV['S3_KEY'],
    :aws_secret_access_key  => ENV['S3_SECRET']
  )
end
