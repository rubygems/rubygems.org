class VaultObject < AWS::S3::S3Object
  set_current_bucket_to "#{Rails.env.downcase}.s3.rubygems.org"

  def self.cf_url_for(path)
    "http://#{Rails.env.downcase}.cf.rubygems.org#{path}"
  end

  def self.s3_url_for(path)
    "http://#{Rails.env.downcase}.s3.rubygems.org#{path}"
  end
end
