# frozen_string_literal: true

module OIDC::TrustedPublisher
  def self.table_name_prefix
    "oidc_trusted_publisher_"
  end

  def self.all
    [GitHubAction, GitLab]
  end

  def self.find_by_url_identifier(identifier)
    all.find { |type| type.url_identifier == identifier }
  end

  def self.find_by_polymorphic_name(name)
    all.find { |type| type.polymorphic_name == name }
  end
end
