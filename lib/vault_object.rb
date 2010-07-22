class VaultObject < AWS::S3::S3Object
  BUCKET = Rails.env.maintenance? ? "production" : Rails.env

  set_current_bucket_to "#{BUCKET}.s3.rubygems.org"

  def self.cf_url_for(path)
    "http://#{BUCKET}.cf.rubygems.org#{path}"
  end

  def self.s3_url_for(path)
    "http://#{BUCKET}.s3.rubygems.org#{path}"
  end
end
