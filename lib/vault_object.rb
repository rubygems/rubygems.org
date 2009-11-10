AWS::S3::Base.establish_connection!(
  :access_key_id     => ENV['S3_KEY'],
  :secret_access_key => ENV['S3_SECRET']
)

class ::VaultObject < AWS::S3::S3Object
  set_current_bucket_to "gemcutter_#{(ENV['RACK_ENV'] || RAILS_ENV).downcase}"
end
