module OIDC::TrustedPublisher
  def self.table_name_prefix
    "oidc_trusted_publisher_"
  end

  def self.all
    [GitHubAction]
  end
end
