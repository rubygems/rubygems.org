if ENV['S3_KEY'] && ENV['S3_SECRET']
  Fog.mock! unless Rails.env == 'production'
  $fog = Fog::AWS::S3.new(
    :aws_access_key_id      => ENV['S3_KEY'],
    :aws_secret_access_key  => ENV['S3_SECRET']
  )
  $fog.directories.create(:key => "#{Rails.env.downcase}.s3.rubygems.org")
end
