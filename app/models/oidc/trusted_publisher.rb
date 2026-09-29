# frozen_string_literal: true

module OIDC::TrustedPublisher
  def self.table_name_prefix
    "oidc_trusted_publisher_"
  end

  def self.all
    [GitHubAction, GitLab]
  end

  def self.available_for(user)
    all.select { |type| type.available_for?(user) }
  end

  def self.find_by_url_identifier(identifier, types: all)
    types.find { |type| type.url_identifier == identifier }
  end

  def self.find_by_polymorphic_name(name, types: all)
    types.find { |type| type.polymorphic_name == name }
  end
end
