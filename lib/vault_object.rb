class VaultObject
  def self.cf_url_for(path)
    "http://#{Vault::S3::BUCKET}.cf.rubygems.org#{path}"
  end

  def self.s3_url_for(path)
    "http://#{Vault::S3::BUCKET}.s3.rubygems.org#{path}"
  end
end
