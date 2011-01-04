if ENV['S3_KEY'] && ENV['S3_SECRET']
  if !Rails.env.production? && !Rails.env.staging?
    Fog.mock!
  end

  $fog = Fog::Storage.new(
    :provider               => 'AWS',
    :aws_access_key_id      => ENV['S3_KEY'],
    :aws_secret_access_key  => ENV['S3_SECRET']
  )
  $fog.directories.create(:key => $rubygems_config[:s3_bucket])
end
